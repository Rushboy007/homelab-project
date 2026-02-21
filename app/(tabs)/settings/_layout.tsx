import { Stack } from 'expo-router';
import { useSettingsStore } from '@/store/useSettingsStore';

export default function SettingsLayout() {
    const colors = useSettingsStore(s => s.getThemeColors());

    return (
        <Stack
            screenOptions={{
                headerStyle: { backgroundColor: colors.background },
                headerTintColor: colors.text,
                headerTitleStyle: { fontWeight: '600' as const },
                contentStyle: { backgroundColor: colors.background },
            }}
        >
            <Stack.Screen name="index" options={{ title: 'Settings' }} />
        </Stack>
    );
}

