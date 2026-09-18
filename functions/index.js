///**
// * Import function triggers from their respective submodules:
// *
// * const {onCall} = require("firebase-functions/v2/https");
// * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
// *
// * See a full list of supported triggers at https://firebase.google.com/docs/functions
// */
//
//const {setGlobalOptions} = require("firebase-functions");
//const {onRequest} = require("firebase-functions/https");
//const logger = require("firebase-functions/logger");
//
//// For cost control, you can set the maximum number of containers that can be
//// running at the same time. This helps mitigate the impact of unexpected
//// traffic spikes by instead downgrading performance. This limit is a
//// per-function limit. You can override the limit for each function using the
//// `maxInstances` option in the function's options, e.g.
//// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
//// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
//// functions should each use functions.runWith({ maxInstances: 10 }) instead.
//// In the v1 API, each function can only serve one request per container, so
//// this will be the maximum concurrent request count.
//setGlobalOptions({ maxInstances: 10 });
//
//// Create and deploy your first functions
//// https://firebase.google.com/docs/functions/get-started
//
//// exports.helloWorld = onRequest((request, response) => {
////   logger.info("Hello logs!", {structuredData: true});
////   response.send("Hello from Firebase!");
//// });
//

const { onRequest } = require("firebase-functions/v2/https");

exports.sendTelegramTest = onRequest(
  {
    cors: true,
  },
  async (req, res) => {
    try {
      const botToken = process.env.TELEGRAM_BOT_TOKEN;

      if (!botToken) {
        console.error("TELEGRAM_BOT_TOKEN is missing");

        return res.status(500).json({
          success: false,
          message: "TELEGRAM_BOT_TOKEN is missing",
        });
      }

      const { chatId, message } = req.body;

      if (!chatId || !message) {
        return res.status(400).json({
          success: false,
          message: "chatId and message are required",
        });
      }

      const telegramUrl =
        `https://api.telegram.org/bot${botToken}/sendMessage`;

      const response = await fetch(telegramUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          chat_id: chatId,
          text: message,
        }),
      });

      const result = await response.json();

      console.log("Telegram response:", result);

      if (!response.ok || !result.ok) {
        return res.status(500).json({
          success: false,
          message: "Telegram API failed",
          telegram: result,
        });
      }

      return res.status(200).json({
        success: true,
        message: "Telegram message sent",
      });
    } catch (error) {
      console.error("Telegram function error:", error);

      return res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  }
);