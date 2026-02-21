import { QueryClientProvider } from '@tanstack/react-query';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import React, { useEffect, useRef, useState } from 'react';
import { View, StyleSheet } from 'react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import Animated, { useSharedValue, useAnimatedStyle, withTiming, Easing } from 'react-native-reanimated';
import { useServicesStore } from '@/store/useServicesStore';
import { useSettingsStore } from '@/store/useSettingsStore';
import { queryClient } from '@/services/queryClient';

SplashScreen.preventAutoHideAsync();



function RootLayoutNav() {
    const isReady = useServicesStore(s => s.isReady);
    const initServices = useServicesStore(s => s.init);
    const colors = useSettingsStore(s => s.getThemeColors());
    const theme = useSettingsStore(s => s.theme);

    const overlayOpacity = useSharedValue(0);
    const [overlayColor, setOverlayColor] = useState(colors.background);
    const prevTheme = useRef(theme);

    // Initialize ServicesStore on mount
    useEffect(() => {
        initServices();
    }, [initServices]);

    useEffect(() => {
        if (isReady) {
            SplashScreen.hideAsync();
        }
    }, [isReady]);

    useEffect(() => {
        if (prevTheme.current !== theme && isReady) {
            // Theme changed, trigger transition
            setOverlayColor(colors.background);
            overlayOpacity.value = 1; // instantly show overlay of NEW color
            overlayOpacity.value = withTiming(0, { duration: 400, easing: Easing.out(Easing.ease) }); // fade out to reveal new theme
        }
        prevTheme.current = theme;
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [theme, isReady, colors.background]);

    const overlayStyle = useAnimatedStyle(() => {
        return {
            opacity: overlayOpacity.value,
            pointerEvents: overlayOpacity.value > 0 ? 'auto' : 'none',
        };
    });

    return (
        <View style={{ flex: 1 }}>
            <Stack
                screenOptions={{
                    headerBackTitle: 'Back',
                    contentStyle: { backgroundColor: colors.background },
                }}
            >
                <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
                <Stack.Screen
                    name="service-login"
                    options={{
                        headerShown: false,
                        presentation: 'modal',
                        animation: 'slide_from_bottom',
                    }}
                />
                <Stack.Screen name="portainer" options={{ headerShown: false }} />
                <Stack.Screen name="pihole" options={{ headerShown: false }} />
                <Stack.Screen name="beszel" options={{ headerShown: false }} />
                <Stack.Screen name="gitea" options={{ headerShown: false }} />
            </Stack>

            <Animated.View
                style={[
                    StyleSheet.absoluteFillObject,
                    { backgroundColor: overlayColor, zIndex: 99999 },
                    overlayStyle
                ]}
            />
        </View>
    );
}

export default function RootLayout() {
    return (
        <QueryClientProvider client={queryClient}>
            <GestureHandlerRootView style={{ flex: 1 }}>
                <RootLayoutNav />
            </GestureHandlerRootView>
        </QueryClientProvider>
    );
}
