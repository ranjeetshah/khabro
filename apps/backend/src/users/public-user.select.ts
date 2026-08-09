/** Fields safe to expose when another authenticated user looks up an author. */
export const PUBLIC_USER_SELECT = {
  id: true,
  name: true,
} as const;
