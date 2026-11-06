import { logger } from "firebase-functions";
import { onCall, HttpsError, CallableRequest } from "firebase-functions/https";
import { defineSecret } from "firebase-functions/params";
import { onSchedule } from "firebase-functions/scheduler";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

initializeApp();
const db = getFirestore();

const clientId = "FelixHan-Listr-SBX-81d2ad8ad-beecadaf";
const ruName = "Felix_Hansen-FelixHan-Listr--cueveor";
const apiBaseURL = "https://api.sandbox.ebay.com";
const ebayClientSecret = defineSecret("EBAY_SANDBOX_CLIENT_SECRET");
const scopes = [
    "https://api.ebay.com/oauth/api_scope",
    "https://api.ebay.com/oauth/api_scope/sell.inventory",
    "https://api.ebay.com/oauth/api_scope/sell.account",
    "https://api.ebay.com/oauth/api_scope/sell.fulfillment.readonly",
];
const oneDayMs = 24 * 60 * 60 * 1000;

interface ExchangeEbayTokenResponse {
    refresh_token: string;
    refresh_token_expires_in: number;
}

interface GetEbayAccessTokenResponse {
    access_token: string;
    expires_in: number;
}

interface EbayOrdersResponse {
    orders?: EbayOrder[];
}

interface EbayOrder {
    lineItems?: EbayLineItem[];
}

interface EbayLineItem {
    sku?: string;
}

const requestEbayToken = async (body: URLSearchParams) => {
    const clientSecret = ebayClientSecret.value();
    const credentials = `${clientId}:${clientSecret}`;
    const encodedCredentials = btoa(credentials);

    const tokenURL = `${apiBaseURL}/identity/v1/oauth2/token`;

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

const accessTokenForUser = async (uid: string) => {
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

    const accessTokenExpiresAt = Date.now() + tokenData.expires_in * 1000;

    return { accessToken, accessTokenExpiresAt };
};

const fetchSoldSKUs = async (accessToken: string, since: Date) => {
    const filter = `creationdate:[${since.toISOString()}..]`;
    const url = `${apiBaseURL}/sell/fulfillment/v1/order` +
        `?filter=${encodeURIComponent(filter)}&limit=200`;

    const response = await fetch(url, {
        headers: { Authorization: `Bearer ${accessToken}` },
    });

    if (!response.ok) {
        const text = await response.text();
        logger.error("eBay orders failed", {
            status: response.status,
            text,
        });

        throw new Error(`getOrders failed with status ${response.status}`);
    }

    const data = (await response.json()) as EbayOrdersResponse;

    const skus: string[] = [];

    for (const order of data.orders ?? []) {
        for (const item of order.lineItems ?? []) {
            if (item.sku) {
                skus.push(item.sku);
            }
        }
    }

    return skus;
};

const syncSoldListingsForUser = async (uid: string) => {
    const privateRef = db.doc(`users/${uid}/private/ebay`);
    const privateDoc = await privateRef.get();
    const lastSyncedAt = privateDoc.get("lastSoldSyncAt");

    const since = lastSyncedAt instanceof Timestamp ?
        lastSyncedAt.toDate() :
        new Date(Date.now() - oneDayMs);

    const runStartedAt = new Date();
    const { accessToken } = await accessTokenForUser(uid);
    const skus = await fetchSoldSKUs(accessToken, since);

    for (const sku of skus) {
        if (sku.includes("/")) {
            continue;
        }

        const postcardRef = db.doc(`users/${uid}/postcards/${sku}`);
        const postcard = await postcardRef.get();

        if (postcard.exists && postcard.get("status") === "listed") {
            await postcardRef.update({
                status: "sold",
            });
        }
    }

    await privateRef.set(
        { lastSoldSyncAt: runStartedAt },
        { merge: true }
    );
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

        return await accessTokenForUser(uid);
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

export const syncSoldListings = onSchedule(
    { schedule: "every 15 minutes", secrets: [ebayClientSecret] },
    async () => {
        const users = await db.collection("users")
            .where("isEbayConnected", "==", true)
            .get();

        for (const user of users.docs) {
            const uid = user.id;

            try {
                await syncSoldListingsForUser(uid);
            } catch (error) {
                logger.error("Sold sync failed", { uid, error });
            }
        }
    }
);
