import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
    View,
    Text,
    StyleSheet,
    TouchableOpacity,
    Alert,
} from 'react-native';
import { useQuery } from '@tanstack/react-query';
import {
    Server,
    HardDrive,
    Image as ImageIcon,
    Cpu,
    MemoryStick,
    ChevronRight,
    Wifi,
    WifiOff,
    Layers,
    Heart,
    HeartOff,
} from 'lucide-react-native';
import { useRouter } from 'expo-router';
import { useServicesStore } from '@/store/useServicesStore';
import { useSettingsStore } from '@/store/useSettingsStore';
import { portainerApi } from '@/services/portainer-api';
import { PortainerEndpoint } from '@/types/portainer';
import { formatBytes } from '@/utils/formatters';
import { ThemeColors } from '@/constants/themes';
import { ServiceDashboardLayout } from '@/components/ServiceDashboardLayout';
import { SkeletonCard } from '@/components/SkeletonLoader';

const PORTAINER_COLOR = '#13B5EA';

export default function PortainerDashboard() {
    const { getConnection } = useServicesStore();
    const connection = getConnection('portainer');
    const router = useRouter();
    const colors = useSettingsStore(s => s.getThemeColors());
    const t = useSettingsStore(s => s.getTranslations());
    const [selectedEndpoint, setSelectedEndpoint] = useState<PortainerEndpoint | null>(null);

    const endpointsQuery = useQuery({
        queryKey: ['portainer-endpoints'],
        queryFn: () => portainerApi.getEndpoints(),
        enabled: !!connection,
        refetchInterval: 30000,
    });

    const endpoints = useMemo(() => endpointsQuery.data ?? [], [endpointsQuery.data]);

    useEffect(() => {
        if (endpointsQuery.isError && connection) {
            Alert.alert('Connessione fallita', 'Impossibile raggiungere Portainer. Verifica di essere sulla rete corretta o configura un URL alternativo nelle impostazioni.');
        }
    }, [endpointsQuery.isError, connection]);

    useEffect(() => {
        if (endpoints.length > 0 && !selectedEndpoint) {
            setSelectedEndpoint(endpoints[0]);
        }
    }, [endpoints, selectedEndpoint]);

    const containersQuery = useQuery({
        queryKey: ['portainer-containers', selectedEndpoint?.Id],
        queryFn: () => portainerApi.getContainers(selectedEndpoint!.Id),
        enabled: !!selectedEndpoint,
        refetchInterval: 15000,
    });

    const containers = useMemo(() => containersQuery.data ?? [], [containersQuery.data]);

    const stats = useMemo(() => {
        const running = containers.filter(c => c.State === 'running').length;
        const stopped = containers.filter(c => c.State === 'exited' || c.State === 'dead').length;
        const paused = containers.filter(c => c.State === 'paused').length;
        return { running, stopped, paused, total: containers.length };
    }, [containers]);

    const snapshot = selectedEndpoint?.Snapshots?.[0];
    const rawInfo = snapshot?.DockerSnapshotRaw;

    const onRefresh = useCallback(() => {
        endpointsQuery.refetch();
        containersQuery.refetch();
    }, [endpointsQuery, containersQuery]);

    const isLoading = endpointsQuery.isLoading || containersQuery.isLoading;
    const isError = endpointsQuery.isError;
    const s = makeStyles(colors);

    return (
        <ServiceDashboardLayout
            isLoading={isLoading && containers.length === 0}
            isError={isError}
            errorMessage={endpointsQuery.error?.message || t.loginErrorFailed}
            onRefresh={onRefresh}
            onRetry={() => endpointsQuery.refetch()}
            refreshColor={PORTAINER_COLOR}
        >
            {endpoints.length > 1 && (
                <View style={s.section}>
                    <Text style={s.sectionTitle}>{t.portainerEndpoints}</Text>
                    {endpoints.map((ep) => (
                        <TouchableOpacity
                            key={ep.Id}
                            style={[s.endpointCard, selectedEndpoint?.Id === ep.Id && s.endpointCardActive]}
                            onPress={() => setSelectedEndpoint(ep)}
                            activeOpacity={0.7}
                        >
                            <View style={s.endpointLeft}>
                                <View style={[s.endpointDot, { backgroundColor: ep.Status === 1 ? colors.running : colors.stopped }]} />
                                <View>
                                    <Text style={s.endpointName}>{ep.Name}</Text>
                                    <Text style={s.endpointUrl}>{ep.URL}</Text>
                                </View>
                            </View>
                            {selectedEndpoint?.Id === ep.Id && (
                                <View style={s.activeBadge}>
                                    <Text style={s.activeBadgeText}>{t.portainerActive}</Text>
                                </View>
                            )}
                        </TouchableOpacity>
                    ))}
                </View>
            )}

            {selectedEndpoint && (
                <View style={s.section}>
                    {containersQuery.isLoading && (
                        <View style={s.cardsContainer}>
                            <SkeletonCard />
                            <SkeletonCard />
                            <SkeletonCard />
                        </View>
                    )}
                    <View style={s.serverHeader}>
                        <View style={s.serverIconWrap}>
                            <Server size={16} color={PORTAINER_COLOR} />
                        </View>
                        <View style={{ flex: 1 }}>
                            <Text style={s.serverName}>{selectedEndpoint.Name}</Text>
                            <View style={s.serverStatusRow}>
                                {selectedEndpoint.Status === 1 ? (
                                    <Wifi size={12} color={colors.running} />
                                ) : (
                                    <WifiOff size={12} color={colors.stopped} />
                                )}
                                <Text style={[s.serverStatus, { color: selectedEndpoint.Status === 1 ? colors.running : colors.stopped }]}>
                                    {selectedEndpoint.Status === 1 ? t.portainerOnline : t.portainerOffline}
                                </Text>
                            </View>
                        </View>
                    </View>
                    {rawInfo && (
                        <View style={s.serverInfoCard}>
                            <InfoItem label="OS" value={rawInfo.OperatingSystem ?? 'N/A'} colors={colors} />
                            <View style={s.divider} />
                            <InfoItem label="Docker" value={rawInfo.ServerVersion ?? snapshot?.DockerVersion ?? 'N/A'} colors={colors} />
                            <View style={s.divider} />
                            <InfoItem label="Arch" value={rawInfo.Architecture ?? 'N/A'} colors={colors} />
                            {rawInfo.Name && (
                                <>
                                    <View style={s.divider} />
                                    <InfoItem label="Host" value={rawInfo.Name} colors={colors} />
                                </>
                            )}
                        </View>
                    )}
                </View>
            )}

            <View style={s.section}>
                <Text style={s.sectionTitle}>{t.portainerContainers}</Text>
                <View style={s.statsGrid}>
                    <StatMiniCard label={t.portainerTotal} value={stats.total} color={colors.info} colors={colors} />
                    <StatMiniCard label={t.portainerRunning} value={stats.running} color={colors.running} colors={colors} />
                    <StatMiniCard label={t.portainerStopped} value={stats.stopped} color={colors.stopped} colors={colors} />
                </View>

                {stats.total > 0 && (
                    <View style={s.containerBar}>
                        {stats.running > 0 && (
                            <View style={[s.barSegment, { flex: stats.running, backgroundColor: colors.running, borderTopLeftRadius: 6, borderBottomLeftRadius: 6, borderTopRightRadius: stats.stopped === 0 && stats.paused === 0 ? 6 : 0, borderBottomRightRadius: stats.stopped === 0 && stats.paused === 0 ? 6 : 0 }]} />
                        )}
                        {stats.paused > 0 && (
                            <View style={[s.barSegment, { flex: stats.paused, backgroundColor: colors.warning }]} />
                        )}
                        {stats.stopped > 0 && (
                            <View style={[s.barSegment, { flex: stats.stopped, backgroundColor: colors.stopped, borderTopRightRadius: 6, borderBottomRightRadius: 6, borderTopLeftRadius: stats.running === 0 && stats.paused === 0 ? 6 : 0, borderBottomLeftRadius: stats.running === 0 && stats.paused === 0 ? 6 : 0 }]} />
                        )}
                    </View>
                )}
            </View>

            {snapshot && (
                <>
                    <View style={s.section}>
                        <Text style={s.sectionTitle}>{t.portainerResources}</Text>
                        <View style={s.resourcesGrid}>
                            <ResourceCard icon={<ImageIcon size={18} color={colors.paused} />} value={String(snapshot.ImageCount)} label={t.portainerImages} color={colors.paused} colors={colors} />
                            <ResourceCard icon={<HardDrive size={18} color={PORTAINER_COLOR} />} value={String(snapshot.VolumeCount)} label={t.portainerVolumes} color={PORTAINER_COLOR} colors={colors} />
                            <ResourceCard icon={<Cpu size={18} color={colors.created} />} value={String(snapshot.TotalCPU)} label={t.portainerCpus} color={colors.created} colors={colors} />
                            <ResourceCard icon={<MemoryStick size={18} color={colors.accentLight} />} value={formatBytes(snapshot.TotalMemory)} label={t.portainerMemory} color={colors.accentLight} colors={colors} />
                        </View>
                    </View>

                    {(snapshot.StackCount > 0 || snapshot.HealthyContainerCount > 0 || snapshot.UnhealthyContainerCount > 0) && (
                        <View style={s.section}>
                            <Text style={s.sectionTitle}>{t.portainerStacks} & Health</Text>
                            <View style={s.healthGrid}>
                                {snapshot.StackCount > 0 && (
                                    <View style={s.healthCard}>
                                        <Layers size={18} color={PORTAINER_COLOR} />
                                        <Text style={s.healthValue}>{snapshot.StackCount}</Text>
                                        <Text adjustsFontSizeToFit numberOfLines={1} style={s.healthLabel}>{t.portainerStacks}</Text>
                                    </View>
                                )}
                                {snapshot.HealthyContainerCount > 0 && (
                                    <View style={s.healthCard}>
                                        <Heart size={18} color={colors.running} />
                                        <Text style={s.healthValue}>{snapshot.HealthyContainerCount}</Text>
                                        <Text adjustsFontSizeToFit numberOfLines={1} style={s.healthLabel}>{t.portainerHealthy}</Text>
                                    </View>
                                )}
                                {snapshot.UnhealthyContainerCount > 0 && (
                                    <View style={s.healthCard}>
                                        <HeartOff size={18} color={colors.stopped} />
                                        <Text style={s.healthValue}>{snapshot.UnhealthyContainerCount}</Text>
                                        <Text adjustsFontSizeToFit numberOfLines={1} style={s.healthLabel}>{t.portainerUnhealthy}</Text>
                                    </View>
                                )}
                            </View>
                        </View>
                    )}
                </>
            )}

            {selectedEndpoint && (
                <TouchableOpacity
                    style={s.viewAllButton}
                    onPress={() => router.push({ pathname: '/portainer/containers' as never, params: { endpointId: String(selectedEndpoint.Id) } })}
                    activeOpacity={0.7}
                >
                    <Text style={s.viewAllText}>{t.portainerViewAll}</Text>
                    <ChevronRight size={18} color={PORTAINER_COLOR} />
                </TouchableOpacity>
            )}
        </ServiceDashboardLayout>
    );
}

function InfoItem({ label, value, colors }: { label: string; value: string; colors: ThemeColors }) {
    return (
        <View style={{ flexDirection: 'row' as const, justifyContent: 'space-between' as const, alignItems: 'center' as const, paddingVertical: 10 }}>
            <Text style={{ fontSize: 14, color: colors.textSecondary }}>{label}</Text>
            <Text style={{ fontSize: 14, color: colors.text, fontWeight: '500' as const, maxWidth: '60%' as unknown as number, textAlign: 'right' as const }} numberOfLines={1}>{value}</Text>
        </View>
    );
}

function StatMiniCard({ label, value, color, colors }: { label: string; value: number; color: string; colors: ThemeColors }) {
    return (
        <View style={{ flex: 1, backgroundColor: colors.surface, borderRadius: 16, padding: 14, borderWidth: 1, borderColor: colors.border, alignItems: 'center' as const, gap: 4 }}>
            <Text style={{ fontSize: 26, fontWeight: '700' as const, color: color }}>{value}</Text>
            <Text adjustsFontSizeToFit numberOfLines={1} style={{ fontSize: 11, color: colors.textSecondary, fontWeight: '500' as const }}>{label}</Text>
        </View>
    );
}

function ResourceCard({ icon, value, label, color, colors }: { icon: React.ReactNode; value: string; label: string; color: string; colors: ThemeColors }) {
    return (
        <View style={{ width: '47%' as unknown as number, flexGrow: 1, backgroundColor: colors.surface, borderRadius: 16, padding: 16, borderWidth: 1, borderColor: colors.border, gap: 6 }}>
            <View style={{ width: 36, height: 36, borderRadius: 10, backgroundColor: color + '1A', alignItems: 'center' as const, justifyContent: 'center' as const, marginBottom: 4 }}>{icon}</View>
            <Text style={{ fontSize: 20, fontWeight: '700' as const, color: colors.text }}>{value}</Text>
            <Text adjustsFontSizeToFit numberOfLines={1} style={{ fontSize: 12, color: colors.textSecondary, fontWeight: '500' as const }}>{label}</Text>
        </View>
    );
}

function makeStyles(colors: ThemeColors) {
    return StyleSheet.create({
        cardsContainer: { paddingVertical: 16, gap: 12 },
        section: { marginBottom: 24 },
        sectionTitle: { fontSize: 13, fontWeight: '600' as const, color: colors.textMuted, marginBottom: 12, textTransform: 'uppercase' as const, letterSpacing: 0.8 },
        serverHeader: { flexDirection: 'row', alignItems: 'center', gap: 12, marginBottom: 14 },
        serverIconWrap: { width: 40, height: 40, borderRadius: 12, backgroundColor: '#13B5EA15', alignItems: 'center', justifyContent: 'center' },
        serverName: { fontSize: 17, fontWeight: '700' as const, color: colors.text },
        serverStatusRow: { flexDirection: 'row', alignItems: 'center', gap: 4, marginTop: 2 },
        serverStatus: { fontSize: 12, fontWeight: '500' as const },
        serverInfoCard: { backgroundColor: colors.surface, borderRadius: 16, paddingHorizontal: 16, paddingVertical: 4, borderWidth: 1, borderColor: colors.border },
        divider: { height: 1, backgroundColor: colors.border },
        statsGrid: { flexDirection: 'row', gap: 10, marginBottom: 12 },
        containerBar: { flexDirection: 'row', height: 8, borderRadius: 6, overflow: 'hidden', backgroundColor: colors.surfaceHover },
        barSegment: { height: '100%' },
        resourcesGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
        healthGrid: { flexDirection: 'row', gap: 10 },
        healthCard: { flex: 1, backgroundColor: colors.surface, borderRadius: 14, padding: 14, borderWidth: 1, borderColor: colors.border, alignItems: 'center', gap: 6 },
        healthValue: { fontSize: 20, fontWeight: '700' as const, color: colors.text },
        healthLabel: { fontSize: 11, color: colors.textSecondary, fontWeight: '500' as const },
        endpointCard: { backgroundColor: colors.surface, borderRadius: 14, padding: 14, marginBottom: 8, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', borderWidth: 1, borderColor: colors.border },
        endpointCardActive: { borderColor: '#13B5EA66', backgroundColor: '#13B5EA0D' },
        endpointLeft: { flexDirection: 'row', alignItems: 'center', gap: 10, flex: 1 },
        endpointDot: { width: 10, height: 10, borderRadius: 5 },
        endpointName: { fontSize: 15, fontWeight: '600' as const, color: colors.text },
        endpointUrl: { fontSize: 12, color: colors.textMuted, marginTop: 2 },
        activeBadge: { backgroundColor: '#13B5EA1A', paddingHorizontal: 8, paddingVertical: 3, borderRadius: 8 },
        activeBadgeText: { color: '#13B5EA', fontSize: 11, fontWeight: '600' as const },
        viewAllButton: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', backgroundColor: colors.surface, borderRadius: 14, paddingVertical: 14, borderWidth: 1, borderColor: colors.border, gap: 6, marginBottom: 8 },
        viewAllText: { color: '#13B5EA', fontSize: 15, fontWeight: '600' as const },
    });
}

