export async function sendNotification(
  taskMsg: string,
  fromUserId: string,
  toUserId: string,
  work_order: number,
  type: string,
  title: string,
) {
  const { token } = useDirectusToken()
  const runtimeConfig = useRuntimeConfig()

  const notify_ulr = runtimeConfig.public.directus.url + `db/send_notification`
  const local_ulr = 'http://localhost:8056/db/send_notification'

  await $fetch(notify_ulr, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token.value}`,
      'Content-Type': 'application/json',
    },
    body: {
      from_user_id: fromUserId,
      to_user_id: toUserId,
      title: title || 'Notification',
      work_order: work_order,
      message: taskMsg,
      type: type,
    },
  })
    .then((response) => {
      console.log('sendNotification response:', response)
      return response
    })
    .catch((error) => {
      console.error('sendNotification error:', error)
      throw error
    })
}
