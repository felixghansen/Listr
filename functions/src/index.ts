import { logger } from "firebase-functions";
import { onCall, HttpsError } from "firebase-functions/https";
import { defineSecret } from "firebase-functions/params";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

initializeApp();

const clientId = "FelixHan-Listr-SBX-81d2ad8ad-beecadaf";
const ruName = "Felix_Hansen-FelixHan-Listr--cueveor";
const tokenURL = "https://api.sandbox.ebay.com/identity/v1/oauth2/token";
const ebayClientSecret = defineSecret("EBAY_SANDBOX_CLIENT_SECRET");

interface EbayTokenResponse {
    refresh_token: string;
    refresh_token_expires_in: number;
}

export const exchangeEbayCode = onCall(
    { secrets: [ebayClientSecret] },
    async (req) => {
        if (!req.auth) {
            throw new HttpsError(
                "unauthenticated",
                "You must be signed in to connect to eBay."
            );
        }

        const uid = req.auth.uid;
        const code = req.data.code;

        if (typeof code !== "string" || code.length === 0) {
            throw new HttpsError(
                "invalid-argument",
                "Missing eBay authorization code."
            );
        }

        const clientSecret = ebayClientSecret.value();
        const credentials = `${clientId}:${clientSecret}`;
        const encodedCredentials = btoa(credentials);

        const response = await fetch(tokenURL, {
            method: "POST",
            headers: {
                "Content-Type": "application/x-www-form-urlencoded",
                "Authorization": `Basic ${encodedCredentials}`,
            },
            body: new URLSearchParams([
                ["grant_type", "authorization_code"],
                ["code", code],
                ["redirect_uri", ruName],
            ]),
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

        const tokenData = (await response.json()) as EbayTokenResponse;
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

        const db = getFirestore();

        await db.doc(`users/${uid}/private/ebay`).set(
            { refreshToken, refreshTokenExpiresAt },
            { merge: true }
        );

        await db.doc(`users/${uid}`).set(
            { ebayConnected: true },
            { merge: true }
        );

        return { success: true };
    }
);
