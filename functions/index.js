const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Trigger: When a new notification document is created in Firestore.
 * Action: Look up the recipient's FCM token and send a push notification.
 */
exports.sendPushNotification = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    const recipientId = notification.recipientId;

    if (!recipientId) {
      console.log("No recipientId found, skipping push notification.");
      return null;
    }

    try {
      // Get the recipient's user document to find their FCM token
      const userDoc = await db.collection("users").doc(recipientId).get();

      if (!userDoc.exists) {
        console.log(`User ${recipientId} not found.`);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log(`No FCM token for user ${recipientId}.`);
        return null;
      }

      // Build the push notification payload
      const message = {
        token: fcmToken,
        notification: {
          title: notification.title || "BFarm",
          body: notification.body || "You have a new notification",
        },
        data: {
          type: notification.type || "general",
          relatedId: notification.relatedId || "",
          notificationId: context.params.notificationId,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "bivfarm_notifications",
            priority: "high",
            defaultSound: true,
          },
        },
      };

      // Send the push notification
      const response = await messaging.send(message);
      console.log(
        `Push notification sent to ${recipientId}: ${response}`
      );
      return response;
    } catch (error) {
      // Handle invalid/expired tokens gracefully
      if (
        error.code === "messaging/invalid-registration-token" ||
        error.code === "messaging/registration-token-not-registered"
      ) {
        console.log(
          `Invalid token for user ${recipientId}, removing token.`
        );
        await db
          .collection("users")
          .doc(recipientId)
          .update({ fcmToken: admin.firestore.FieldValue.delete() });
      } else {
        console.error("Error sending push notification:", error);
      }
      return null;
    }
  });

/**
 * Trigger: When a new bid is created.
 * Action: Notify the seller (farmer) and any assigned agent.
 */
exports.onBidCreated = functions.firestore
  .document("bids/{bidId}")
  .onCreate(async (snap, context) => {
    const bid = snap.data();
    const sellerId = bid.sellerId;

    if (!sellerId) return null;

    try {
      // Notify the farmer
      const sellerDoc = await db.collection("users").doc(sellerId).get();
      if (sellerDoc.exists) {
        const seller = sellerDoc.data();

        // Also notify the agent if assigned
        if (seller.agentId) {
          await db.collection("notifications").add({
            recipientId: seller.agentId,
            title: "New Bid on Farmer Product",
            body: `${bid.buyerName || "A buyer"} placed a bid of UGX ${bid.offeredPrice} on ${bid.productName} (${seller.name || "your farmer"})`,
            type: "bid",
            relatedId: context.params.bidId,
            isRead: false,
            createdAt: new Date().toISOString(),
          });
        }
      }
    } catch (error) {
      console.error("Error in onBidCreated:", error);
    }

    return null;
  });
