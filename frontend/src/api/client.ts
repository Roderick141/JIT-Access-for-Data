/**
 * Thin fetch wrapper for the Flask REST API.
 *
 * During development Vite proxies /api/* to Flask on :5001,
 * so all paths are relative (e.g. "/api/me").
 */

export interface ApiResponse<T = unknown> {
  ok: boolean;
  data?: T;
  message?: string;
  error?: string;
}

class ApiError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.name = "ApiError";
    this.status = status;
  }
}

async function request<T>(
  url: string,
  options: RequestInit = {}
): Promise<T> {
  const res = await fetch(url, {
    credentials: "same-origin", // send session cookie
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(options.headers || {}),
    },
  });

  const body: ApiResponse<T> = await res.json();

  if (!res.ok || !body.ok) {
    throw new ApiError(
      body.error || body.message || `Request failed (${res.status})`,
      res.status
    );
  }

  return body.data as T;
}

export const api = {
  get<T>(url: string): Promise<T> {
    return request<T>(url, { method: "GET" });
  },

  post<T>(url: string, data?: unknown): Promise<T> {
    return request<T>(url, {
      method: "POST",
      body: data !== undefined ? JSON.stringify(data) : undefined,
    });
  },
};

export { ApiError };
