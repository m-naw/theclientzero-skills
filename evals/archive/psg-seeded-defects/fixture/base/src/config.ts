/** Runtime configuration, all values read at boot. */
export const config = {
  smtpHost: process.env['SMTP_HOST'] ?? 'localhost',
  maxRetries: Number(process.env['MAX_RETRIES'] ?? 3),
};
