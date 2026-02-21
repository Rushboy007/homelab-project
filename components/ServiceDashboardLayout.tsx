import React, { ReactNode } from 'react';
import {
    View,
    Text,
    StyleSheet,
    ScrollView,
    RefreshControl,
    TouchableOpacity,
} from 'react-native';
import { AlertTriangle } from 'lucide-react-native';
import { useSettingsStore } from '@/store/useSettingsStore';
import { SkeletonCard } from '@/components/SkeletonLoader';
import { ThemeColors } from '@/constants/themes';

interface ServiceDashboardLayoutProps {
    children: ReactNode;
    isLoading: boolean;
    isError: boolean;
    errorMessage?: string;
    onRefresh: () => void;
    onRetry: () => void;
    refreshColor?: string;
    skeletonCount?: number;
}

export function ServiceDashboardLayout({
    children,
    isLoading,
    isError,
    errorMessage,
    onRefresh,
    onRetry,
    refreshColor = '#FFFFFF',
    skeletonCount = 3,
}: ServiceDashboardLayoutProps) {
    const colors = useSettingsStore(s => s.getThemeColors());
    const t = useSettingsStore(s => s.getTranslations());
    const s = makeStyles(colors);

    if (isLoading && !isError) {
        return (
            <View style={s.loadingContainer}>
                <View style={s.cardsContainer}>
                    {Array.from({ length: skeletonCount }).map((_, i) => (
                        <SkeletonCard key={i} />
                    ))}
                </View>
            </View>
        );
    }

    if (isError) {
        return (
            <View style={s.errorContainer}>
                <AlertTriangle size={48} color={colors.warning} />
                <Text style={s.errorTitle}>{t.error || 'Errore di connessione'}</Text>
                <Text style={s.errorMessage}>
                    {errorMessage || 'Non è stato possibile caricare i dati. Verifica la connessione.'}
                </Text>
                <TouchableOpacity
                    style={[s.retryButton, { backgroundColor: refreshColor }]}
                    onPress={onRetry}
                    activeOpacity={0.7}
                >
                    <Text style={s.retryText}>{t.retry || 'Riprova'}</Text>
                </TouchableOpacity>
            </View>
        );
    }

    return (
        <ScrollView
            style={s.container}
            contentContainerStyle={s.content}
            refreshControl={
                <RefreshControl
                    refreshing={false} // Always false since we rely on Zustand queries state
                    onRefresh={onRefresh}
                    tintColor={refreshColor}
                />
            }
        >
            {children}
            <View style={{ height: 30 }} />
        </ScrollView>
    );
}

function makeStyles(colors: ThemeColors) {
    return StyleSheet.create({
        container: {
            flex: 1,
            backgroundColor: colors.background,
        },
        content: {
            paddingHorizontal: 16,
            paddingTop: 16,
        },
        loadingContainer: {
            flex: 1,
            backgroundColor: colors.background,
        },
        cardsContainer: {
            padding: 16,
            paddingBottom: 40,
            gap: 12,
        },
        errorContainer: {
            flex: 1,
            backgroundColor: colors.background,
            alignItems: 'center',
            justifyContent: 'center',
            gap: 12,
            paddingHorizontal: 24,
        },
        errorTitle: {
            fontSize: 18,
            fontWeight: '600' as const,
            color: colors.text,
            marginTop: 8,
        },
        errorMessage: {
            fontSize: 14,
            color: colors.textSecondary,
            textAlign: 'center',
            lineHeight: 20,
        },
        retryButton: {
            paddingHorizontal: 24,
            paddingVertical: 12,
            borderRadius: 12,
            marginTop: 8,
        },
        retryText: {
            color: '#FFF',
            fontSize: 15,
            fontWeight: '600' as const,
        },
    });
}
