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
  let res: Response;
  try {
    res = await fetch(url, {
      credentials: "same-origin",
      ...options,
      headers: {
        "Content-Type": "application/json",
        ...(options.headers || {}),
      },
    });
  } catch (err) {
    throw new ApiError(
      err instanceof Error ? err.message : "Network request failed",
      0
    );
  }

  const text = await res.text();
  if (!text) {
    if (!res.ok) {
      throw new ApiError(`Request failed (${res.status})`, res.status);
    }
    return undefined as T;
  }

  let body: ApiResponse<T>;
  try {
    body = JSON.parse(text) as ApiResponse<T>;
  } catch {
    if (!res.ok) {
      throw new ApiError(`Request failed (${res.status})`, res.status);
    }
    throw new ApiError("Invalid JSON response.", res.status);
  }

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

  put<T>(url: string, data?: unknown): Promise<T> {
    return request<T>(url, {
      method: "PUT",
      body: data !== undefined ? JSON.stringify(data) : undefined,
    });
  },

  delete<T>(url: string): Promise<T> {
    return request<T>(url, { method: "DELETE" });
  },
};

export { ApiError };
