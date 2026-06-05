interface FcmMessage {
  title: string;
  body: string;
  data?: Record<string, string>;
}

export async function sendFcmPush(
  tokens: string[],
  message: FcmMessage,
): Promise<number> {
  const serverKey = Deno.env.get("FCM_SERVER_KEY");
  if (!serverKey || tokens.length === 0) {
    return 0;
  }

  let sent = 0;

  for (const token of tokens) {
    const response = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        Authorization: `key=${serverKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        to: token,
        notification: {
          title: message.title,
          body: message.body,
        },
        data: message.data ?? {},
        priority: "high",
      }),
    });

    if (response.ok) {
      sent += 1;
    } else {
      console.error("FCM error:", token, await response.text());
    }
  }

  return sent;
}
