import { QueryClient } from '@tanstack/react-query';

export const queryClient = new QueryClient({
    defaultOptions: {
        queries: {
            retry: 1, // Only retry once to avoid endless loops on dead services
            staleTime: 1000 * 30, // Consider data fresh for 30s
            refetchOnWindowFocus: true, // Auto-refresh when app comes to foreground
        },
    },
});
