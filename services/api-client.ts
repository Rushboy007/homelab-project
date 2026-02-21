import { ServiceType } from '@/types/services';
import { useServicesStore } from '@/store/useServicesStore';

export const REQUEST_TIMEOUT = 8000;

export abstract class BaseAPIClient {
    protected baseUrl: string = '';
    protected fallbackUrl: string = '';
    protected abstract readonly serviceType: ServiceType;

    public getBaseUrl(): string {
        return this.baseUrl;
    }

    public setFallbackUrl(fallbackUrl: string) {
        this.fallbackUrl = fallbackUrl.replace(/\/+$/, '');
        console.log(`[${this.constructor.name}] Fallback URL set:`, this.fallbackUrl);
    }

    public getFallbackUrl(): string {
        return this.fallbackUrl;
    }

    protected async fetchWithTimeout(url: string, options: RequestInit = {}, customTimeout: number = REQUEST_TIMEOUT): Promise<Response> {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), customTimeout);
        try {
            const response = await fetch(url, { ...options, signal: controller.signal });
            this.interceptResponse(response);
            return response;
        } finally {
            clearTimeout(timeout);
        }
    }

    /**
     * Intercepts standard responses and globally handles 401 Unauthorized errors 
     * by automatically disconnecting the service via the store.
     */
    protected interceptResponse(response: Response) {
        if (response.status === 401) {
            console.warn(`[${this.constructor.name}] 401 Unauthorized intercepted! Disconnecting service: ${this.serviceType}`);
            useServicesStore.getState().disconnectService(this.serviceType);
        }
    }

    /**
     * Standard internal request wrapper that handles primary vs fallback URLs.
     */
    protected async requestBase<T>(
        path: string,
        options: RequestInit,
        parseResponse: (response: Response) => Promise<T> = async (res) => (await res.json()) as Promise<T>
    ): Promise<T> {
        const primaryUrl = `${this.baseUrl}${path}`;
        console.log(`[${this.constructor.name}] Request:`, options.method || 'GET', primaryUrl);

        try {
            const response = await this.fetchWithTimeout(primaryUrl, options);
            if (!response.ok) {
                const errorText = await response.text().catch(() => 'Unknown error');
                throw new Error(`${this.constructor.name} error: ${response.status} - ${errorText}`);
            }
            return await parseResponse(response);
        } catch (primaryError) {
            if (this.fallbackUrl) {
                const fallbackFullUrl = `${this.fallbackUrl}${path}`;
                console.log(`[${this.constructor.name}] Primary failed, trying fallback:`, fallbackFullUrl, (primaryError as Error).message);
                try {
                    const response = await this.fetchWithTimeout(fallbackFullUrl, options);
                    if (!response.ok) {
                        const errorText = await response.text().catch(() => 'Unknown error');
                        throw new Error(`${this.constructor.name} error: ${response.status} - ${errorText}`);
                    }
                    return await parseResponse(response);
                } catch (fallbackError) {
                    console.error(`[${this.constructor.name}] Fallback also failed:`, (fallbackError as Error).message);
                    throw new Error(`Connessione fallita su entrambi gli URL. Verifica la rete.`);
                }
            }
            throw primaryError;
        }
    }
}
