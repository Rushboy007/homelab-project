import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Appearance } from 'react-native';
import { Language, translations, Translations } from '@/constants/translations';
import { ThemeMode, ThemeColors, darkTheme, lightTheme } from '@/constants/themes';

interface SettingsState {
    language: Language;
    theme: ThemeMode;
    setLanguage: (lang: Language) => void;
    setTheme: (th: ThemeMode) => void;
    getTranslations: () => Translations;
    getThemeColors: () => ThemeColors;
}

export const useSettingsStore = create<SettingsState>()(
    persist(
        (set, get) => ({
            language: 'it',
            theme: Appearance.getColorScheme() === 'light' ? 'light' : 'dark',

            setLanguage: (lang: Language) => set({ language: lang }),

            setTheme: (th: ThemeMode) => {
                Appearance.setColorScheme(th);
                set({ theme: th });
            },

            getTranslations: () => translations[get().language],

            getThemeColors: () => get().theme === 'dark' ? darkTheme : lightTheme,
        }),
        {
            name: 'homelab-settings-storage',
            storage: createJSONStorage(() => AsyncStorage),
            onRehydrateStorage: () => (state) => {
                if (state) {
                    Appearance.setColorScheme(state.theme);
                }
            },
        }
    )
);
