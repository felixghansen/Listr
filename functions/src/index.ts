import { logger } from "firebase-functions";
import { onCall, HttpsError, CallableRequest } from "firebase-functions/https";
import { defineSecret } from "firebase-functions/params";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

initializeApp();
const db = getFirestore();

const clientId = "FelixHan-Listr-SBX-81d2ad8ad-beecadaf";
const ruName = "Felix_Hansen-FelixHan-Listr--cueveor";
const tokenURL = "https://api.sandbox.ebay.com/identity/v1/oauth2/token";
const ebayClientSecret = defineSecret("EBAY_SANDBOX_CLIENT_SECRET");
const scopes = [
    "https://api.ebay.com/oauth/api_scope",
    "https://api.ebay.com/oauth/api_scope/sell.inventory",
    "https://api.ebay.com/oauth/api_scope/sell.account",
];

interface ExchangeEbayTokenResponse {
    refresh_token: string;
    refresh_token_expires_in: number;
}

interface GetEbayAccessTokenResponse {
    access_token: string;
    expires_in: number;
}

const requestEbayToken = async (body: URLSearchParams) => {
    const clientSecret = ebayClientSecret.value();
    const credentials = `${clientId}:${clientSecret}`;
    const encodedCredentials = btoa(credentials);

    const response = await fetch(tokenURL, {
        method: "POST",
        headers: {
            "Content-Type": "application/x-www-form-urlencoded",
            "Authorization": `Basic ${encodedCredentials}`,
        },
        body,
    });

    if (!response.ok) {
        const text = await response.text();
        logger.error("eBay token exchange failed", {
            status: response.status,
            text,
        });

        if (response.status === 400) {
            throw new HttpsError(
                "invalid-argument",
                "Your eBay sign-in expired. Please connect again."
            );
        }

        if (response.status >= 500) {
            throw new HttpsError(
                "unavailable",
                "eBay isn't responding right now. Please try again later."
            );
        }

        throw new HttpsError(
            "internal",
            "Couldn't connect your eBay account. Please try again."
        );
    }

    return response;
};

const requireUid = (req: CallableRequest): string => {
    if (!req.auth) {
        throw new HttpsError("unauthenticated", "You need to be signed in.");
    }
    return req.auth.uid;
};

export const exchangeEbayCode = onCall(
    { secrets: [ebayClientSecret] },
    async (req) => {
        const uid = requireUid(req);
        const code = req.data.code;

        if (typeof code !== "string" || code.length === 0) {
            throw new HttpsError(
                "invalid-argument",
                "Missing eBay authorization code."
            );
        }

        const body = new URLSearchParams([
            ["grant_type", "authorization_code"],
            ["code", code],
            ["redirect_uri", ruName],
        ]);

        const response = await requestEbayToken(body);

        const tokenData = (await response.json()) as ExchangeEbayTokenResponse;
        const refreshToken = tokenData.refresh_token;

        if (typeof refreshToken !== "string") {
            logger.error("eBay response had no refresh token", {
                keys: Object.keys(tokenData),
            });
            throw new HttpsError(
                "internal",
                "Couldn't connect your eBay account. Please try again."
            );
        }

        const expiresInMs = tokenData.refresh_token_expires_in * 1000;
        const refreshTokenExpiresAt = new Date(Date.now() + expiresInMs);

        await db.doc(`users/${uid}/private/ebay`).set(
            { refreshToken, refreshTokenExpiresAt },
            { merge: true }
        );

        await db.doc(`users/${uid}`).set(
            { isEbayConnected: true },
            { merge: true }
        );

        return { success: true };
    }
);

export const getEbayAccessToken = onCall(
    { secrets: [ebayClientSecret] },
    async (req) => {
        const uid = requireUid(req);

        const snapshot = await db.doc(`users/${uid}/private/ebay`).get();
        const refreshToken = snapshot.get("refreshToken");

        if (typeof refreshToken !== "string") {
            throw new HttpsError(
                "failed-precondition",
                "Connect your eBay account first."
            );
        }

        const body = new URLSearchParams([
            ["grant_type", "refresh_token"],
            ["refresh_token", refreshToken],
            ["scope", scopes.join(" ")],
        ]);

        let response: Response;

        try {
            response = await requestEbayToken(body);
        } catch (error) {
            if (
                error instanceof HttpsError &&
                error.code === "invalid-argument"
            ) {
                await db.doc(`users/${uid}`).set(
                    { isEbayConnected: false },
                    { merge: true }
                );

                throw new HttpsError(
                    "failed-precondition",
                    error.message
                );
            }

            throw error;
        }

        const tokenData = (await response.json()) as GetEbayAccessTokenResponse;
        const accessToken = tokenData.access_token;

        if (typeof accessToken !== "string") {
            logger.error("eBay had no access token", {
                keys: Object.keys(tokenData),
            });

            throw new HttpsError(
                "internal",
                "Couldn't reach eBay. Please try again."
            );
        }

        const expiresInMs = tokenData.expires_in * 1000;
        const accessTokenExpiresAt = Date.now() + expiresInMs;

        return { accessToken, accessTokenExpiresAt };
    }
);

export const disconnectEbay = onCall(
    async (req) => {
        const uid = requireUid(req);
        const userPath = `users/${uid}`;

        const batch = db.batch();

        batch.delete(
            db.doc(`${userPath}/private/ebay`)
        );

        batch.set(
            db.doc(userPath),
            { isEbayConnected: false },
            { merge: true }
        );

        try {
            await batch.commit();
        } catch (error) {
            logger.error("Couldn't disconnect eBay", { uid, error });
            throw new HttpsError(
                "internal",
                "Couldn't disconnect your eBay account. Please try again."
            );
        }

        return { success: true };
    }
);
