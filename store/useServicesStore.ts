import { create } from 'zustand';
import * as Keychain from 'react-native-keychain';
import { ServiceType, ServiceConnection } from '@/types/services';
import { portainerApi } from '@/services/portainer-api';
import { piholeApi } from '@/services/pihole-api';
import { beszelApi } from '@/services/beszel-api';
import { giteaApi } from '@/services/gitea-api';
import { queryClient } from '@/services/queryClient';

const SERVICES_KEY = 'homelab_services';

const SERVICE_APIS: Record<ServiceType, { ping: () => Promise<boolean> }> = {
    portainer: portainerApi,
    pihole: piholeApi,
    beszel: beszelApi,
    gitea: giteaApi,
};

interface ServicesState {
    connections: Partial<Record<ServiceType, ServiceConnection>>;
    isReady: boolean;
    reachability: Partial<Record<ServiceType, boolean | null>>;
    pinging: Partial<Record<ServiceType, boolean>>;

    // Actions
    init: () => Promise<void>;
    connectService: (connection: ServiceConnection) => Promise<void>;
    disconnectService: (type: ServiceType) => Promise<void>;
    checkReachability: (type: ServiceType) => Promise<void>;
    checkAllReachability: (conns: Partial<Record<ServiceType, ServiceConnection>>) => Promise<void>;
    updateServiceFallbackUrl: (type: ServiceType, fallbackUrl: string) => Promise<void>;

    // Selectors helpers (exposed as regular state properties that can be derived in components, but providing them as action-like functions can be handy, although Zustand prefers derivation in components)
    getConnection: (type: ServiceType) => ServiceConnection | null;
    isConnected: (type: ServiceType) => boolean;
    isReachable: (type: ServiceType) => boolean | null | undefined;
    isPinging: (type: ServiceType) => boolean;
    connectedCount: () => number;
}

const persistConnections = async (updated: Partial<Record<ServiceType, ServiceConnection>>) => {
    await Keychain.setGenericPassword('homelab_user', JSON.stringify(updated), { service: SERVICES_KEY });
    console.log('[ServicesStore] Persisted Securely:', Object.keys(updated));
};

export const useServicesStore = create<ServicesState>((set, get) => ({
    connections: {},
    isReady: false,
    reachability: {},
    pinging: {},

    init: async () => {
        try {
            const credentials = await Keychain.getGenericPassword({ service: SERVICES_KEY });
            if (credentials && credentials.password) {
                const data = JSON.parse(credentials.password) as Partial<Record<ServiceType, ServiceConnection>>;
                console.log('[ServicesStore] Restored Securely:', Object.keys(data));

                set({ connections: data });

                if (data.portainer) {
                    if (data.portainer.apiKey) {
                        portainerApi.configureWithApiKey(data.portainer.url, data.portainer.apiKey, data.portainer.fallbackUrl);
                    } else {
                        portainerApi.configure(data.portainer.url, data.portainer.token, data.portainer.fallbackUrl);
                    }
                }
                if (data.pihole) piholeApi.configure(data.pihole.url, data.pihole.token, data.pihole.fallbackUrl);
                if (data.beszel) beszelApi.configure(data.beszel.url, data.beszel.token, data.beszel.fallbackUrl);
                if (data.gitea) giteaApi.configure(data.gitea.url, data.gitea.token, data.gitea.fallbackUrl);

                const initialReachability: Partial<Record<ServiceType, null>> = {};
                (Object.keys(data) as ServiceType[]).forEach((t) => { initialReachability[t] = null; });
                set({ reachability: initialReachability });

                set({ isReady: true });

                // Fire and forget health checks
                get().checkAllReachability(data);
            } else {
                set({ isReady: true });
            }
        } catch (error) {
            console.error('[ServicesStore] Error during init:', error);
            set({ isReady: true });
        }
    },

    checkReachability: async (type: ServiceType) => {
        set((state) => ({
            pinging: { ...state.pinging, [type]: true },
            reachability: { ...state.reachability, [type]: null }
        }));
        console.log('[ServicesStore] Pinging', type);
        try {
            const ok = await SERVICE_APIS[type].ping();
            console.log('[ServicesStore] Ping result:', type, ok);
            set((state) => ({
                reachability: { ...state.reachability, [type]: ok }
            }));
            if (ok) {
                queryClient.invalidateQueries({ queryKey: [type] });
            }
        } catch {
            set((state) => ({
                reachability: { ...state.reachability, [type]: false }
            }));
        } finally {
            set((state) => ({
                pinging: { ...state.pinging, [type]: false }
            }));
        }
    },

    checkAllReachability: async (conns: Partial<Record<ServiceType, ServiceConnection>>) => {
        const types = Object.keys(conns) as ServiceType[];
        if (types.length === 0) return;
        console.log('[ServicesStore] Checking reachability for:', types);
        await Promise.all(types.map(t => get().checkReachability(t)));
    },

    connectService: async (connection: ServiceConnection) => {
        const { connections, checkReachability } = get();
        const updated = { ...connections, [connection.type]: connection };
        set({ connections: updated });
        await persistConnections(updated);

        switch (connection.type) {
            case 'portainer':
                if (connection.apiKey) {
                    portainerApi.configureWithApiKey(connection.url, connection.apiKey, connection.fallbackUrl);
                } else {
                    portainerApi.configure(connection.url, connection.token, connection.fallbackUrl);
                }
                break;
            case 'pihole': piholeApi.configure(connection.url, connection.token, connection.fallbackUrl); break;
            case 'beszel': beszelApi.configure(connection.url, connection.token, connection.fallbackUrl); break;
            case 'gitea': giteaApi.configure(connection.url, connection.token, connection.fallbackUrl); break;
        }
        console.log('[ServicesStore] Connected:', connection.type);

        set((state) => ({
            reachability: { ...state.reachability, [connection.type]: null }
        }));
        checkReachability(connection.type);
    },

    disconnectService: async (type: ServiceType) => {
        const { connections } = get();
        const updated = { ...connections };
        delete updated[type];
        set({ connections: updated });

        set((state) => {
            const newReachability = { ...state.reachability };
            delete newReachability[type];
            return { reachability: newReachability };
        });

        await persistConnections(updated);
        queryClient.removeQueries(); // Clears react-query caches
        console.log('[ServicesStore] Disconnected:', type);
    },

    updateServiceFallbackUrl: async (type: ServiceType, fallbackUrl: string) => {
        const { connections } = get();
        const conn = connections[type];
        if (!conn) return;
        const updated = { ...connections, [type]: { ...conn, fallbackUrl: fallbackUrl || undefined } };
        set({ connections: updated });
        await persistConnections(updated);

        switch (type) {
            case 'portainer': portainerApi.setFallbackUrl(fallbackUrl); break;
            case 'pihole': piholeApi.setFallbackUrl(fallbackUrl); break;
            case 'beszel': beszelApi.setFallbackUrl(fallbackUrl); break;
            case 'gitea': giteaApi.setFallbackUrl(fallbackUrl); break;
        }
        console.log('[ServicesStore] Fallback URL updated for', type, ':', fallbackUrl);
    },

    getConnection: (type: ServiceType) => get().connections[type] ?? null,

    isConnected: (type: ServiceType) => !!get().connections[type],

    isReachable: (type: ServiceType) => {
        if (!get().connections[type]) return undefined;
        return get().reachability[type] ?? null;
    },

    isPinging: (type: ServiceType) => !!get().pinging[type],

    connectedCount: () => Object.keys(get().connections).length,
}));
