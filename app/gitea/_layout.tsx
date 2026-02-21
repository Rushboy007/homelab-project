import { Stack } from 'expo-router';
import { useSettingsStore } from '@/store/useSettingsStore';

export default function GiteaLayout() {
    const colors = useSettingsStore(s => s.getThemeColors());
    const t = useSettingsStore(s => s.getTranslations());

    return (
        <Stack
            screenOptions={{
                headerStyle: { backgroundColor: colors.background },
                headerTintColor: colors.text,
                headerTitleStyle: { fontWeight: '600' as const },
                contentStyle: { backgroundColor: colors.background },
                headerBackTitle: '',
            }}
        >
            <Stack.Screen name="index" options={{ title: 'Gitea' }} />
            <Stack.Screen name="[repoId]" options={{ title: '' }} />
        </Stack>
    );
}

