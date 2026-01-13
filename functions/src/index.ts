import { onCall, HttpsError } from "firebase-functions/v2/https";
import { setGlobalOptions, logger } from "firebase-functions/v2";
import admin from "firebase-admin";

if (!admin.apps?.length) {
  admin.initializeApp();
}

const messaging = admin.messaging();

setGlobalOptions({
  region: "asia-southeast1",
  memory: "512MiB",
  timeoutSeconds: 120,
  maxInstances: 10,
});

interface FCMResponse {
  success: boolean;
  messageId?: string;
  error?: string;
  results?: any;
  invalidTokens?: string[];
}

interface NotificationData {
  token?: string;
  tokens?: string[];
  topic?: string;
  title: string;
  body: string;
  data?: { [key: string]: string };
  imageUrl?: string;
}

function validateNotificationInput(data: NotificationData): string | null {
  // if (!data.title?.trim()) return "Title is required";
  // if (!data.body?.trim()) return "Body is required";
  // if (data.title.length > 100) return "Title too long";
  // if (data.body.length > 500) return "Body too long";
  return null;
}

function createMessage(data: NotificationData): any {
  return {
    data: {
      ...data.data,
      title: data.title,
      body: data.body,
      imageUrl: data.imageUrl || "",
      timestamp: Math.floor(Date.now() / 1000).toString(),
    },
    android: {
      priority: "high",
      ttl: 3600000,
    },
    apns: {
      headers: { "apns-priority": "10" },
      payload: {
        aps: {
          "content-available": 1,
        },
      },
    },
  };
}

const callableOptions = {
  cors: true,
  region: "asia-southeast1",
  memory: "512MiB" as const,
  timeoutSeconds: 120,
};

export const sendNotificationToToken = onCall(
  callableOptions,
  async (request): Promise<FCMResponse> => {
    const data = request.data as NotificationData;
    try {
      const validationError = validateNotificationInput(data);
      if (validationError)
        throw new HttpsError("invalid-argument", validationError);

      if (!data.token?.trim()) {
        throw new HttpsError("invalid-argument", "FCM token is required");
      }

      const message = createMessage(data);
      message.token = data.token;
      const response = await messaging.send(message);
      logger.info("Notification sent successfully", { messageId: response });
      return { success: true, messageId: response };
    } catch (error: any) {
      logger.error("Error sending to token", { error: error.message });
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", error.message || "Unknown error");
    }
  }
);

export const sendNotificationToMultipleTokens = onCall(
  callableOptions,
  async (request): Promise<FCMResponse> => {
    const data = request.data as NotificationData;
    try {
      const validationError = validateNotificationInput(data);
      if (validationError)
        throw new HttpsError("invalid-argument", validationError);

      if (!data.tokens?.length)
        throw new HttpsError("invalid-argument", "tokens array is required");

      if (data.tokens.length > 500)
        throw new HttpsError("invalid-argument", "Maximum 500 tokens");

      const validTokens = data.tokens.filter(
        (token) => token?.trim().length >= 140
      );
      if (!validTokens.length)
        throw new HttpsError("invalid-argument", "No valid tokens found");

      const message = createMessage(data);
      message.tokens = validTokens;

      const response = await messaging.sendEachForMulticast(message);

      const invalidTokens: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success && resp.error) {
          const code = resp.error.code;
          if (
            code === "messaging/registration-token-not-registered" ||
            code === "messaging/invalid-registration-token"
          ) {
            invalidTokens.push(validTokens[idx]);
          }
        }
      });

      logger.info("Multicast sent", {
        success: response.successCount,
        failed: response.failureCount,
      });

      return {
        success: true,
        results: {
          successCount: response.successCount,
          failureCount: response.failureCount,
        },
        invalidTokens,
      };
    } catch (error: any) {
      logger.error("Error sending multicast", { error: error.message });
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", error.message || "Unknown error");
    }
  }
);

export const sendNotificationToTopic = onCall(
  callableOptions,
  async (request): Promise<FCMResponse> => {
    const data = request.data as NotificationData;
    try {
      const validationError = validateNotificationInput(data);
      if (validationError)
        throw new HttpsError("invalid-argument", validationError);

      if (!data.topic?.trim())
        throw new HttpsError("invalid-argument", "Topic is required");

      const message = createMessage(data);
      message.topic = data.topic;

      const response = await messaging.send(message);
      logger.info("Topic notification sent", { messageId: response });
      return { success: true, messageId: response };
    } catch (error: any) {
      logger.error("Error sending to topic", { error: error.message });
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", error.message || "Unknown error");
    }
  }
);
