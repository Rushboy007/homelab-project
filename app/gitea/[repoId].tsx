import React, { useState, useCallback, useMemo } from 'react';
import {
    View,
    Text,
    StyleSheet,
    ScrollView,
    RefreshControl,
    ActivityIndicator,
    TouchableOpacity,
    Modal,
    Alert,
    Share,
    useWindowDimensions,
} from 'react-native';
import { useLocalSearchParams, Stack, useRouter } from 'expo-router';
import { useQuery } from '@tanstack/react-query';
import {
    FileText,
    GitCommit,
    CircleDot,
    GitBranch,
    Folder,
    File,
    Star,
    Lock,
    Unlock,
    ChevronRight,
    ArrowLeft,
    Shield,
    X,
    Code,
    Share2,
    Maximize2,
    ChevronDown,
    BookOpen,
} from 'lucide-react-native';
import { Image } from 'expo-image';
import Markdown, { ASTNode } from 'react-native-markdown-display';

import * as Haptics from 'expo-haptics';
import { useSettingsStore } from '@/store/useSettingsStore';
import { giteaApi } from '@/services/gitea-api';
import { GiteaFileContent } from '@/types/gitea';
import { ThemeColors } from '@/constants/themes';
import { formatBytes } from '@/utils/formatters';

const GITEA_COLOR = '#609926';

const safeBase64Decode = (str: string): string => {
    try {
        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
        let output = '';
        let input = str.replace(/[^A-Za-z0-9+/=]/g, '');
        for (let i = 0; i < input.length; i += 4) {
            const enc1 = chars.indexOf(input.charAt(i));
            const enc2 = chars.indexOf(input.charAt(i + 1));
            const enc3 = chars.indexOf(input.charAt(i + 2));
            const enc4 = chars.indexOf(input.charAt(i + 3));
            if (enc1 === -1 || enc2 === -1) continue;
            const chr1 = (enc1 << 2) | (enc2 >> 4);
            const chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
            const chr3 = ((enc3 & 3) << 6) | enc4;
            output += String.fromCharCode(chr1);
            if (enc3 !== 64 && enc3 !== -1) output += String.fromCharCode(chr2);
            if (enc4 !== 64 && enc4 !== -1) output += String.fromCharCode(chr3);
        }
        return decodeURIComponent(escape(output));
    } catch (e) {
        // Fallback for binary data or failed UTF-8 conversion
        try {
            const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
            let output = '';
            let input = str.replace(/[^A-Za-z0-9+/=]/g, '');
            for (let i = 0; i < input.length; i += 4) {
                const enc1 = chars.indexOf(input.charAt(i));
                const enc2 = chars.indexOf(input.charAt(i + 1));
                const enc3 = chars.indexOf(input.charAt(i + 2));
                const enc4 = chars.indexOf(input.charAt(i + 3));
                if (enc1 === -1 || enc2 === -1) continue;
                output += String.fromCharCode((enc1 << 2) | (enc2 >> 4));
                if (enc3 !== 64 && enc3 !== -1) output += String.fromCharCode(((enc2 & 15) << 4) | (enc3 >> 2));
                if (enc4 !== 64 && enc4 !== -1) output += String.fromCharCode(((enc3 & 3) << 6) | enc4);
            }
            return output;
        } catch {
            try { return atob(str); } catch { return 'Error decoding binary content'; }
        }
    }
};

const decodeFileContent = (content?: string, encoding?: string): string => {
    if (!content) return '';
    let decoded = '';
    if (encoding === 'base64') {
        decoded = safeBase64Decode(content.replace(/\n/g, ''));
    } else {
        decoded = content;
    }
    if (decoded.length > 5000) {
        return decoded.substring(0, 5000) + '\n\n--- [TRUNCATED FOR PERFORMANCE] ---';
    }
    return decoded;
};

const CodeHighlighter = ({ code, extension, colors }: { code: string; extension: string; colors: ThemeColors }) => {
    // Simple regex-based highlighting for common languages
    const getTokens = (text: string) => {
        const tokens: { text: string; color?: string; fontWeight?: any }[] = [];
        const patterns = [
            { name: 'comment', regex: /(\/\/.*|\/\*[\s\S]*?\*\/|#.*)/g, color: colors.textMuted },
            { name: 'string', regex: /("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|`(?:[^`\\]|\\.)*`)/g, color: '#CE9178' },
            { name: 'keyword', regex: /\b(await|break|case|catch|class|const|continue|debugger|default|delete|do|else|enum|export|extends|false|finally|for|function|if|import|in|instanceof|new|null|return|super|switch|this|throw|true|try|typeof|var|void|while|with|yield|let|static|async|from|as|def|import|from|elif|lambda|pass|global|nonlocal|assert|with|del|yield)\b/g, color: '#569CD6', fontWeight: '600' },
            { name: 'number', regex: /\b(\d+\.?\d*)\b/g, color: '#B5CEA8' },
            { name: 'function', regex: /\b([a-zA-Z_]\w*)(?=\s*\()/g, color: '#DCDCAA' },
            { name: 'boolean', regex: /\b(true|false)\b/g, color: '#569CD6' },
            { name: 'property', regex: /([a-zA-Z_]\w*)(?=\s*:)/g, color: '#9CDCFE' },
        ];

        let lastIndex = 0;
        const matches: { start: number; end: number; color: string; fontWeight?: any; type: string }[] = [];

        patterns.forEach(p => {
            let match;
            p.regex.lastIndex = 0;
            while ((match = p.regex.exec(text)) !== null) {
                matches.push({ start: match.index, end: p.regex.lastIndex, color: p.color, fontWeight: p.fontWeight, type: p.name });
            }
        });

        matches.sort((a, b) => a.start - b.start);

        let filteredMatches: typeof matches = [];
        let currentEnd = 0;
        for (const m of matches) {
            if (m.start >= currentEnd) {
                filteredMatches.push(m);
                currentEnd = m.end;
            }
        }

        let currentIndex = 0;
        filteredMatches.forEach(m => {
            if (m.start > currentIndex) {
                tokens.push({ text: text.substring(currentIndex, m.start) });
            }
            tokens.push({ text: text.substring(m.start, m.end), color: m.color, fontWeight: m.fontWeight });
            currentIndex = m.end;
        });

        if (currentIndex < text.length) {
            tokens.push({ text: text.substring(currentIndex) });
        }

        return tokens;
    };

    const tokens = useMemo(() => getTokens(code), [code, colors]);

    return (
        <Text style={{ fontFamily: 'monospace', fontSize: 13, color: colors.text }}>
            {tokens.map((t, i) => (
                <Text key={i} style={{ color: t.color || colors.text, fontWeight: t.fontWeight || '400' }}>
                    {t.text}
                </Text>
            ))}
        </Text>
    );
};

type TabType = 'files' | 'commits' | 'issues' | 'branches';

export default function GiteaRepoDetail() {
    const { owner, repoName, path, file } = useLocalSearchParams<{
        repoId: string;
        owner: string;
        repoName: string;
        fullName: string;
        path?: string;
        file?: string;
    }>();
    const router = useRouter();
    const colors = useSettingsStore(s => s.getThemeColors());
    const t = useSettingsStore(s => s.getTranslations());
    const [activeTab, setActiveTab] = useState<TabType>('files');
    const currentPath = path || '';
    const viewingFile = file || null;
    const [fullscreenFile, setFullscreenFile] = useState<boolean>(false);

    const [selectedBranch, setSelectedBranch] = useState<string | null>(null);
    const [viewMode, setViewMode] = useState<'preview' | 'code'>('preview');
    const [showBranchModal, setShowBranchModal] = useState<boolean>(false);
    const { width: windowWidth } = useWindowDimensions();

    const repoQuery = useQuery({
        queryKey: ['gitea-repo', owner, repoName],
        queryFn: () => giteaApi.getRepo(owner, repoName),
        enabled: !!owner && !!repoName,
        staleTime: 30000,
    });

    const repo = repoQuery.data;
    const effectiveBranch = selectedBranch || repo?.default_branch;

    const filesQuery = useQuery({
        queryKey: ['gitea-files', owner, repoName, currentPath, effectiveBranch],
        queryFn: () => giteaApi.getRepoContents(owner, repoName, currentPath, effectiveBranch),
        enabled: !!owner && !!repoName && activeTab === 'files' && !!effectiveBranch,
        staleTime: 30000,
    });

    const fileContentQuery = useQuery({
        queryKey: ['gitea-file-content', owner, repoName, viewingFile, effectiveBranch],
        queryFn: () => giteaApi.getFileContent(owner, repoName, viewingFile!, effectiveBranch),
        enabled: !!owner && !!repoName && !!viewingFile && !!effectiveBranch,
        staleTime: 60000,
    });

    const commitsQuery = useQuery({
        queryKey: ['gitea-commits', owner, repoName, effectiveBranch],
        queryFn: () => giteaApi.getRepoCommits(owner, repoName, 1, 30, effectiveBranch),
        enabled: !!owner && !!repoName && activeTab === 'commits' && !!effectiveBranch,
        staleTime: 30000,
    });

    const issuesQuery = useQuery({
        queryKey: ['gitea-issues', owner, repoName],
        queryFn: () => giteaApi.getRepoIssues(owner, repoName, 'open', 1, 30),
        enabled: !!owner && !!repoName && activeTab === 'issues',
        staleTime: 30000,
    });

    const branchesQuery = useQuery({
        queryKey: ['gitea-branches', owner, repoName],
        queryFn: () => giteaApi.getRepoBranches(owner, repoName),
        enabled: !!owner && !!repoName, // Load branches broadly to populate selector
        staleTime: 60000,
    });

    const readmeQuery = useQuery({
        queryKey: ['gitea-readme', owner, repoName, effectiveBranch],
        queryFn: () => giteaApi.getRepoReadme(owner, repoName, effectiveBranch),
        enabled: !!owner && !!repoName && activeTab === 'files' && currentPath === '' && !!effectiveBranch,
        staleTime: 30000,
        retry: false, // README might not exist
    });

    const files = filesQuery.data ?? [];
    const commits = commitsQuery.data ?? [];
    const issues = issuesQuery.data ?? [];
    const branches = branchesQuery.data ?? [];

    const sortedFiles = [...files].sort((a, b) => {
        if (a.type === 'dir' && b.type !== 'dir') return -1;
        if (a.type !== 'dir' && b.type === 'dir') return 1;
        return a.name.localeCompare(b.name);
    });

    const onRefresh = useCallback(() => {
        if (activeTab === 'files') {
            filesQuery.refetch();
            if (currentPath === '') readmeQuery.refetch();
        }
        if (activeTab === 'commits') commitsQuery.refetch();
        if (activeTab === 'issues') issuesQuery.refetch();
        if (activeTab === 'branches') branchesQuery.refetch();
    }, [activeTab, currentPath, filesQuery, readmeQuery, commitsQuery, issuesQuery, branchesQuery]);

    const handleFilePress = useCallback((file: GiteaFileContent) => {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
        if (file.type === 'dir') {
            router.push(`/gitea/${owner}-${repoName}?owner=${owner}&repoName=${repoName}&path=${encodeURIComponent(file.path)}`);
        } else {
            router.push(`/gitea/${owner}-${repoName}?owner=${owner}&repoName=${repoName}&path=${encodeURIComponent(currentPath)}&file=${encodeURIComponent(file.path)}`);
        }
    }, [owner, repoName, currentPath, router]);

    const handleBackPath = useCallback(() => {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
        router.back();
    }, [router]);



    const handleShareFile = useCallback(async () => {
        if (!viewingFile || !owner || !repoName) return;
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
        const rawUrl = `${giteaApi.getBaseUrl()}/api/v1/repos/${owner}/${repoName}/raw/${encodeURIComponent(viewingFile)}`;
        try {
            await Share.share({
                message: rawUrl,
                title: 'Condividi File Gitea',
            });
        } catch {
            Alert.alert('Errore', 'Impossibile condividere il link.');
        }
    }, [viewingFile, owner, repoName]);

    const s = makeStyles(colors);

    const formatCommitDate = (dateStr: string): string => {
        const date = new Date(dateStr);
        const now = new Date();
        const diff = now.getTime() - date.getTime();
        const hours = Math.floor(diff / (1000 * 60 * 60));
        if (hours < 1) return 'adesso';
        if (hours < 24) return `${hours}h fa`;
        const days = Math.floor(hours / 24);
        if (days === 1) return 'ieri';
        if (days < 30) return `${days}g fa`;
        return date.toLocaleDateString('it-IT', { day: '2-digit', month: '2-digit', year: '2-digit' });
    };

    const isImageFile = (filename: string | null) => {
        if (!filename) return false;
        const ext = filename.split('.').pop()?.toLowerCase();
        return ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'svg'].includes(ext || '');
    };

    const markdownStyles = {
        body: { color: colors.text, fontSize: 14, lineHeight: 22 },
        heading1: { color: colors.text, fontSize: 24, fontWeight: 'bold' as const, marginTop: 16, marginBottom: 8 },
        heading2: { color: colors.text, fontSize: 20, fontWeight: 'bold' as const, marginTop: 16, marginBottom: 8, borderBottomWidth: 1, borderBottomColor: colors.border, paddingBottom: 4 },
        heading3: { color: colors.text, fontSize: 18, fontWeight: 'bold' as const, marginTop: 16, marginBottom: 8 },
        link: { color: GITEA_COLOR, textDecorationLine: 'none' as const },
        code_inline: { backgroundColor: colors.surfaceHover, color: colors.text, paddingHorizontal: 4, paddingVertical: 2, borderRadius: 4, fontFamily: 'monospace' },
        code_block: { backgroundColor: colors.surfaceHover, color: colors.text, padding: 12, borderRadius: 8, fontFamily: 'monospace', marginVertical: 8 },
        fence: { backgroundColor: colors.surfaceHover, color: colors.text, padding: 12, borderRadius: 8, fontFamily: 'monospace', marginVertical: 8 },
        blockquote: { borderLeftWidth: 4, borderLeftColor: colors.border, paddingLeft: 12, marginVertical: 8, color: colors.textMuted },
        hr: { backgroundColor: colors.border, height: 1, marginVertical: 16 },
        list_item: { marginVertical: 4 },
        image: { borderRadius: 8, marginVertical: 8 },
    };

    const markdownRules = {
        image: (node: ASTNode, children: any, parent: any, styles: any) => {
            let uri = node.attributes.src;
            if (uri && !uri.startsWith('http')) {
                const cleanUri = uri.startsWith('/') ? uri.slice(1) : uri;
                uri = `${giteaApi.getBaseUrl()}/api/v1/repos/${owner}/${repoName}/raw/${encodeURIComponent(cleanUri)}?ref=${encodeURIComponent(effectiveBranch || repo?.default_branch || '')}`;
            }

            return (
                <Image
                    key={node.key}
                    source={{
                        uri,
                        headers: {
                            Authorization: giteaApi.getAuthHeader(),
                        },
                    }}
                    style={{ width: '100%', height: 200, borderRadius: 8, marginVertical: 8 }}
                    contentFit="contain"
                    transition={200}
                />
            );
        },
    };

    const tabs: { key: TabType; label: string; icon: React.ReactNode }[] = [
        { key: 'files', label: t.giteaFiles, icon: <FileText size={14} color={activeTab === 'files' ? GITEA_COLOR : colors.textMuted} /> },
        { key: 'commits', label: t.giteaCommits, icon: <GitCommit size={14} color={activeTab === 'commits' ? GITEA_COLOR : colors.textMuted} /> },
        { key: 'issues', label: t.giteaIssues, icon: <CircleDot size={14} color={activeTab === 'issues' ? GITEA_COLOR : colors.textMuted} /> },
        { key: 'branches', label: t.giteaBranches, icon: <GitBranch size={14} color={activeTab === 'branches' ? GITEA_COLOR : colors.textMuted} /> },
    ];

    const getHeaderTitle = () => {
        if (viewingFile) return viewingFile.split('/').pop() || '';
        if (currentPath) return currentPath.split('/').pop() || '';
        return repoName || '';
    };

    const headerTitle = getHeaderTitle();
    const displayHeaderTitle = headerTitle.length > 20 ? headerTitle.substring(0, 17) + '...' : headerTitle;

    const fileContent = fileContentQuery.data;
    const decodedContent = useMemo(() =>
        fileContent ? decodeFileContent(fileContent.content, fileContent.encoding) : ''
        , [fileContent?.content, fileContent?.encoding]);

    const readmeContent = useMemo(() =>
        readmeQuery.data ? decodeFileContent(readmeQuery.data.content, readmeQuery.data.encoding) : ''
        , [readmeQuery.data?.content, readmeQuery.data?.encoding]);

    return (
        <>
            <Stack.Screen options={{ title: displayHeaderTitle }} />
            <ScrollView
                style={s.container}
                contentContainerStyle={s.content}
                refreshControl={<RefreshControl refreshing={false} onRefresh={onRefresh} tintColor={GITEA_COLOR} />}
            >
                {repo && (
                    <View style={s.repoHeader}>
                        <View style={s.repoTitleRow}>
                            {repo.private ? <Lock size={16} color={colors.warning} /> : <Unlock size={16} color={colors.textMuted} />}
                            <Text style={s.repoFullName}>{repo.full_name}</Text>
                        </View>
                        {repo.description ? (
                            <Text style={s.repoDesc}>{repo.description}</Text>
                        ) : null}
                        <View style={s.repoMetaRow}>
                            <View style={s.repoMetaItem}>
                                <Star size={13} color={colors.warning} />
                                <Text style={s.repoMetaText}>{repo.stars_count}</Text>
                            </View>
                            <View style={s.repoMetaItem}>
                                <GitBranch size={13} color={colors.info} />
                                <Text style={s.repoMetaText}>{branchesQuery.data?.length ?? 0}</Text>
                            </View>
                            <View style={s.repoMetaItem}>
                                <CircleDot size={13} color={colors.running} />
                                <Text style={s.repoMetaText}>{repo.open_issues_count}</Text>
                            </View>
                            {repo.language ? (
                                <View style={s.repoMetaItem}>
                                    <View style={[s.langDot, { backgroundColor: GITEA_COLOR }]} />
                                    <Text style={s.repoMetaText}>{repo.language}</Text>
                                </View>
                            ) : null}
                        </View>
                        <View style={s.repoInfoRow}>
                            <Text style={s.repoInfoLabel}>Branch:</Text>
                            <TouchableOpacity style={s.branchSelectorBtn} onPress={() => setShowBranchModal(true)} activeOpacity={0.7}>
                                <GitBranch size={11} color={GITEA_COLOR} />
                                <Text style={s.branchBadgeText} numberOfLines={1}>{effectiveBranch}</Text>
                                <ChevronDown size={11} color={GITEA_COLOR} />
                            </TouchableOpacity>
                            <Text style={s.repoInfoSep}>•</Text>
                            <Text style={s.repoInfoLabel}>{formatBytes(repo.size * 1024)}</Text>
                        </View>
                    </View>
                )}

                <View style={s.tabBar}>
                    {tabs.map((tab) => (
                        <TouchableOpacity
                            key={tab.key}
                            style={[s.tab, activeTab === tab.key && s.tabActive]}
                            onPress={() => {
                                Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                                setActiveTab(tab.key);
                                if (tab.key === 'files') {
                                    router.replace(`/gitea/${owner}-${repoName}?owner=${owner}&repoName=${repoName}`);
                                }
                            }}
                            activeOpacity={0.7}
                        >
                            {tab.icon}
                            <Text adjustsFontSizeToFit numberOfLines={1} style={[s.tabText, activeTab === tab.key && s.tabTextActive]}>
                                {tab.label}
                            </Text>
                        </TouchableOpacity>
                    ))}
                </View>

                {activeTab === 'files' && !viewingFile && (
                    <View style={s.tabContent}>
                        {currentPath !== '' && (
                            <TouchableOpacity style={s.backPathRow} onPress={handleBackPath} activeOpacity={0.7}>
                                <ArrowLeft size={16} color={GITEA_COLOR} />
                                <Text style={s.backPathText}>{currentPath}</Text>
                            </TouchableOpacity>
                        )}
                        {filesQuery.isLoading ? (
                            <ActivityIndicator size="small" color={GITEA_COLOR} style={{ paddingVertical: 30 }} />
                        ) : sortedFiles.length === 0 ? (
                            <View style={s.emptyState}>
                                <FileText size={32} color={colors.textMuted} />
                                <Text style={s.emptyText}>{t.giteaNoFiles}</Text>
                            </View>
                        ) : (
                            <View style={s.fileList}>
                                {sortedFiles.map((file, idx) => (
                                    <TouchableOpacity
                                        key={file.sha + file.name}
                                        style={[s.fileItem, idx < sortedFiles.length - 1 && s.fileItemBorder]}
                                        onPress={() => handleFilePress(file)}
                                        activeOpacity={0.7}
                                    >
                                        {file.type === 'dir' ? (
                                            <Folder size={18} color={GITEA_COLOR} />
                                        ) : (
                                            <File size={18} color={colors.textMuted} />
                                        )}
                                        <Text style={[s.fileName, file.type === 'dir' && { color: GITEA_COLOR }]} numberOfLines={1}>
                                            {file.name}
                                        </Text>
                                        {file.type === 'dir' && <ChevronRight size={16} color={colors.textMuted} />}
                                        {file.type === 'file' && file.size > 0 && (
                                            <Text style={s.fileSize}>{formatBytes(file.size)}</Text>
                                        )}
                                    </TouchableOpacity>
                                ))}
                            </View>
                        )}

                        {currentPath === '' && readmeQuery.data && !viewingFile && (
                            <View style={s.readmeCard}>
                                <View style={s.readmeHeader}>
                                    <BookOpen size={16} color={colors.textMuted} />
                                    <Text style={s.readmeTitle}>README.md</Text>
                                </View>
                                <View style={s.readmeContent}>
                                    <Markdown style={markdownStyles} rules={markdownRules}>
                                        {readmeContent}
                                    </Markdown>
                                </View>
                            </View>
                        )}
                    </View>
                )}

                {activeTab === 'files' && viewingFile && (
                    <View style={s.tabContent}>
                        <TouchableOpacity style={s.backPathRow} onPress={handleBackPath} activeOpacity={0.7}>
                            <ArrowLeft size={16} color={GITEA_COLOR} />
                            <Text style={s.backPathText}>{viewingFile}</Text>
                        </TouchableOpacity>

                        {(viewingFile || '').toLowerCase().endsWith('.md') || isImageFile(viewingFile) ? (
                            <View style={s.segmentControl}>
                                <TouchableOpacity style={[s.segmentBtn, viewMode === 'preview' && s.segmentBtnActive]} onPress={() => setViewMode('preview')}>
                                    <Text adjustsFontSizeToFit numberOfLines={1} style={[s.segmentBtnText, viewMode === 'preview' && s.segmentBtnTextActive]}>{t.giteaPreview}</Text>
                                </TouchableOpacity>
                                <TouchableOpacity style={[s.segmentBtn, viewMode === 'code' && s.segmentBtnActive]} onPress={() => setViewMode('code')}>
                                    <Text adjustsFontSizeToFit numberOfLines={1} style={[s.segmentBtnText, viewMode === 'code' && s.segmentBtnTextActive]}>{t.giteaCode}</Text>
                                </TouchableOpacity>
                            </View>
                        ) : null}

                        {fileContentQuery.isLoading ? (
                            <View style={s.fileContentLoading}>
                                <ActivityIndicator size="small" color={GITEA_COLOR} />
                                <Text style={s.loadingFileText}>{t.loading}</Text>
                            </View>
                        ) : fileContentQuery.isError ? (
                            <View style={s.fileContentError}>
                                <Text style={s.fileContentErrorText}>{t.error}</Text>
                            </View>
                        ) : (
                            <View style={s.fileContentCard}>
                                <View style={s.fileContentHeader}>
                                    <Code size={14} color={GITEA_COLOR} />
                                    <Text style={s.fileContentTitle} numberOfLines={1}>
                                        {viewingFile.split('/').pop()}
                                    </Text>
                                    {fileContent && fileContent.size > 0 && (
                                        <Text style={s.fileContentSize}>{formatBytes(fileContent.size)}</Text>
                                    )}
                                    <TouchableOpacity onPress={handleShareFile} hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }} style={s.fileActionBtn}>
                                        <Share2 size={16} color={GITEA_COLOR} />
                                    </TouchableOpacity>
                                    <TouchableOpacity onPress={() => setFullscreenFile(true)} hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }} style={s.fileActionBtn}>
                                        <Maximize2 size={16} color={GITEA_COLOR} />
                                    </TouchableOpacity>
                                </View>
                                {fileContent && fileContent.size > 100000 ? (
                                    <View style={{ padding: 24, alignItems: 'center' }}>
                                        <FileText size={48} color={colors.textMuted} />
                                        <Text style={{ color: colors.text, marginTop: 12, textAlign: 'center' }}>
                                            {t.error} - File too large for preview ({formatBytes(fileContent.size)})
                                        </Text>
                                    </View>
                                ) : isImageFile(viewingFile) ? (
                                    viewMode === 'preview' ? (
                                        <View style={[s.fileImageContainer, { padding: 16 }]}>
                                            <Image
                                                source={{ uri: `data:image/${viewingFile?.split('.').pop()};base64,${fileContentQuery.data?.content?.replace(/[\n\r]/g, '') || ''}` }}
                                                style={[s.fileImage, { width: windowWidth - 64, height: 300 }]}
                                                contentFit="contain"
                                                transition={200}
                                            />
                                        </View>
                                    ) : (
                                        <ScrollView nestedScrollEnabled style={s.fileContentScroll}>
                                            <ScrollView horizontal showsHorizontalScrollIndicator>
                                                <View style={s.fileContentTextContainer}>
                                                    <Text style={s.fileContentText} selectable>
                                                        {decodedContent || t.noData}
                                                    </Text>
                                                </View>
                                            </ScrollView>
                                        </ScrollView>
                                    )
                                ) : viewingFile.toLowerCase().endsWith('.md') ? (
                                    <ScrollView nestedScrollEnabled style={s.fileContentScroll}>
                                        {viewMode === 'preview' ? (
                                            <View style={s.fileMarkdownContainer}>
                                                <Markdown style={markdownStyles} rules={markdownRules}>
                                                    {decodedContent || t.noData}
                                                </Markdown>
                                            </View>
                                        ) : (
                                            <ScrollView horizontal showsHorizontalScrollIndicator>
                                                <View style={s.fileContentTextContainer}>
                                                    <Text style={s.fileContentText} selectable>
                                                        {decodedContent || t.noData}
                                                    </Text>
                                                </View>
                                            </ScrollView>
                                        )}
                                    </ScrollView>
                                ) : (
                                    <ScrollView nestedScrollEnabled style={s.fileContentScroll}>
                                        {viewMode === 'preview' ? (
                                            <ScrollView horizontal showsHorizontalScrollIndicator contentContainerStyle={{ flexGrow: 1 }}>
                                                <View style={{ padding: 16 }}>
                                                    <CodeHighlighter
                                                        code={decodedContent || t.noData}
                                                        extension={(viewingFile || '').split('.').pop() || ''}
                                                        colors={colors}
                                                    />
                                                </View>
                                            </ScrollView>
                                        ) : (
                                            <ScrollView horizontal showsHorizontalScrollIndicator>
                                                <View style={s.fileContentTextContainer}>
                                                    <Text style={s.fileContentText} selectable>
                                                        {decodedContent || t.noData}
                                                    </Text>
                                                </View>
                                            </ScrollView>
                                        )}
                                    </ScrollView>
                                )}
                            </View>
                        )}
                    </View>
                )}

                {activeTab === 'commits' && (
                    <View style={s.tabContent}>
                        {commitsQuery.isLoading ? (
                            <ActivityIndicator size="small" color={GITEA_COLOR} style={{ paddingVertical: 30 }} />
                        ) : commits.length === 0 ? (
                            <View style={s.emptyState}>
                                <GitCommit size={32} color={colors.textMuted} />
                                <Text style={s.emptyText}>{t.giteaNoCommits}</Text>
                            </View>
                        ) : (
                            <View style={s.commitList}>
                                {commits.map((commit, idx) => (
                                    <View key={commit.sha} style={[s.commitItem, idx < commits.length - 1 && s.commitItemBorder]}>
                                        <View style={s.commitDotLine}>
                                            <View style={s.commitDot} />
                                            {idx < commits.length - 1 && <View style={s.commitLine} />}
                                        </View>
                                        <View style={s.commitContent}>
                                            <Text style={s.commitMessage} numberOfLines={2}>
                                                {commit.commit.message.split('\n')[0]}
                                            </Text>
                                            <View style={s.commitMeta}>
                                                <Text style={s.commitAuthor}>
                                                    {commit.commit.author.name}
                                                </Text>
                                                <Text style={s.commitDate}>
                                                    {formatCommitDate(commit.commit.author.date)}
                                                </Text>
                                            </View>
                                            <Text style={s.commitSha}>{commit.sha.substring(0, 8)}</Text>
                                        </View>
                                    </View>
                                ))}
                            </View>
                        )}
                    </View>
                )}

                {activeTab === 'issues' && (
                    <View style={s.tabContent}>
                        {issuesQuery.isLoading ? (
                            <ActivityIndicator size="small" color={GITEA_COLOR} style={{ paddingVertical: 30 }} />
                        ) : issues.length === 0 ? (
                            <View style={s.emptyState}>
                                <CircleDot size={32} color={colors.textMuted} />
                                <Text style={s.emptyText}>{t.giteaNoIssues}</Text>
                            </View>
                        ) : (
                            <View style={s.issueList}>
                                {issues.map((issue, idx) => (
                                    <View key={issue.id} style={[s.issueItem, idx < issues.length - 1 && s.issueItemBorder]}>
                                        <View style={[s.issueIconWrap, { backgroundColor: issue.state === 'open' ? colors.running + '18' : colors.stopped + '18' }]}>
                                            <CircleDot size={16} color={issue.state === 'open' ? colors.running : colors.stopped} />
                                        </View>
                                        <View style={s.issueContent}>
                                            <Text style={s.issueTitle} numberOfLines={2}>#{issue.number} {issue.title}</Text>
                                            <View style={s.issueMeta}>
                                                <Text style={s.issueAuthor}>{issue.user.login}</Text>
                                                <Text style={s.issueDate}>{formatCommitDate(issue.created_at)}</Text>
                                                {issue.comments > 0 && (
                                                    <Text style={s.issueComments}>💬 {issue.comments}</Text>
                                                )}
                                            </View>
                                            {issue.labels.length > 0 && (
                                                <View style={s.labelsRow}>
                                                    {issue.labels.slice(0, 3).map((label) => (
                                                        <View key={label.id} style={[s.labelBadge, { backgroundColor: `#${label.color}33` }]}>
                                                            <Text style={[s.labelText, { color: `#${label.color}` }]}>{label.name}</Text>
                                                        </View>
                                                    ))}
                                                </View>
                                            )}
                                        </View>
                                    </View>
                                ))}
                            </View>
                        )}
                    </View>
                )}

                {activeTab === 'branches' && (
                    <View style={s.tabContent}>
                        {branchesQuery.isLoading ? (
                            <ActivityIndicator size="small" color={GITEA_COLOR} style={{ paddingVertical: 30 }} />
                        ) : branches.length === 0 ? (
                            <View style={s.emptyState}>
                                <GitBranch size={32} color={colors.textMuted} />
                                <Text style={s.emptyText}>{t.giteaNoFiles}</Text>
                            </View>
                        ) : (
                            <View style={s.branchList}>
                                {branches.map((branch, idx) => (
                                    <View key={branch.name} style={[s.branchItem, idx < branches.length - 1 && s.branchItemBorder]}>
                                        <View style={[s.branchIcon, { backgroundColor: GITEA_COLOR + '18' }]}>
                                            <GitBranch size={16} color={GITEA_COLOR} />
                                        </View>
                                        <View style={s.branchContent}>
                                            <View style={s.branchNameRow}>
                                                <Text style={s.branchName}>{branch.name}</Text>
                                                {branch.protected && (
                                                    <View style={s.protectedBadge}>
                                                        <Shield size={10} color={colors.warning} />
                                                    </View>
                                                )}
                                                {repo?.default_branch === branch.name && (
                                                    <View style={s.defaultBadge}>
                                                        <Text style={s.defaultBadgeText}>default</Text>
                                                    </View>
                                                )}
                                            </View>
                                            <Text style={s.branchCommit} numberOfLines={1}>
                                                {branch.commit.message.split('\n')[0]}
                                            </Text>
                                        </View>
                                    </View>
                                ))}
                            </View>
                        )}
                    </View>
                )}

                <View style={{ height: 30 }} />
                <View style={{ height: 30 }} />
            </ScrollView>

            <Modal visible={showBranchModal} animationType="fade" transparent={true} onRequestClose={() => setShowBranchModal(false)}>
                <View style={s.modalOverlay}>
                    <View style={[s.modalContent, { backgroundColor: colors.surface }]}>
                        <View style={s.modalHeader}>
                            <Text style={[s.modalTitle, { color: colors.text }]}>Branch</Text>
                            <TouchableOpacity onPress={() => setShowBranchModal(false)} style={s.modalCloseBtn} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
                                <X size={20} color={colors.textMuted} />
                            </TouchableOpacity>
                        </View>
                        <ScrollView style={s.modalScroll}>
                            {branchesQuery.data?.map(b => (
                                <TouchableOpacity
                                    key={b.name}
                                    style={[s.modalBranchItem, effectiveBranch === b.name && { backgroundColor: GITEA_COLOR + '18' }]}
                                    onPress={() => {
                                        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                                        setSelectedBranch(b.name);
                                        setShowBranchModal(false);
                                        // Reset view state safely
                                        router.replace(`/gitea/${owner}-${repoName}?owner=${owner}&repoName=${repoName}`);
                                    }}
                                >
                                    <GitBranch size={16} color={effectiveBranch === b.name ? GITEA_COLOR : colors.textMuted} />
                                    <Text style={[s.modalBranchText, { color: effectiveBranch === b.name ? GITEA_COLOR : colors.text }]}>
                                        {b.name}
                                    </Text>
                                    {b.name === repo?.default_branch && (
                                        <View style={s.defaultBadge}>
                                            <Text style={s.defaultBadgeText}>default</Text>
                                        </View>
                                    )}
                                </TouchableOpacity>
                            ))}
                        </ScrollView>
                    </View>
                </View>
            </Modal>

            <Modal
                visible={fullscreenFile && !!viewingFile}
                animationType="slide"
                presentationStyle="fullScreen"
                onRequestClose={() => setFullscreenFile(false)}
            >
                <View style={[s.fullscreenContainer, { backgroundColor: colors.background }]}>
                    <View style={[s.fullscreenHeader, { backgroundColor: colors.surface, borderBottomColor: colors.border }]}>
                        <View style={s.fullscreenHeaderLeft}>
                            <Code size={14} color={GITEA_COLOR} />
                            <Text style={[s.fullscreenTitle, { color: colors.text }]} numberOfLines={1}>
                                {viewingFile?.split('/').pop()}
                            </Text>
                        </View>
                        <View style={s.fullscreenActions}>
                            <TouchableOpacity onPress={handleShareFile} hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }} style={s.fileActionBtn}>
                                <Share2 size={18} color={GITEA_COLOR} />
                            </TouchableOpacity>
                            <TouchableOpacity onPress={() => setFullscreenFile(false)} hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }} style={s.fileActionBtn}>
                                <X size={20} color={colors.textMuted} />
                            </TouchableOpacity>
                        </View>
                    </View>
                    {isImageFile(viewingFile) ? (
                        viewMode === 'preview' ? (
                            <View style={[s.fullscreenContainer, { justifyContent: 'center', alignItems: 'center' }]}>
                                <Image
                                    source={{ uri: `data:image/${viewingFile?.split('.').pop()};base64,${fileContentQuery.data?.content?.replace(/\n/g, '')}` }}
                                    style={{ width: windowWidth, height: '80%' }}
                                    contentFit="contain"
                                    transition={200}
                                />
                            </View>
                        ) : (
                            <ScrollView style={s.fullscreenScroll} contentContainerStyle={s.fullscreenScrollContent}>
                                <ScrollView horizontal showsHorizontalScrollIndicator>
                                    <View style={s.fileContentTextContainer}>
                                        <Text style={[s.fileContentText, { color: colors.text }]} selectable>
                                            {decodedContent || t.noData}
                                        </Text>
                                    </View>
                                </ScrollView>
                            </ScrollView>
                        )
                    ) : viewingFile?.toLowerCase().endsWith('.md') ? (
                        <ScrollView style={s.fullscreenScroll} contentContainerStyle={s.fullscreenScrollContent}>
                            <ScrollView horizontal showsHorizontalScrollIndicator={viewMode === 'code'}>
                                {viewMode === 'preview' ? (
                                    <View style={[s.fileMarkdownContainer, { padding: 16, minWidth: '100%' }]}>
                                        <Markdown style={markdownStyles} rules={markdownRules}>
                                            {decodedContent || t.noData}
                                        </Markdown>
                                    </View>
                                ) : (
                                    <View style={s.fileContentTextContainer}>
                                        <Text style={[s.fileContentText, { color: colors.text }]} selectable>
                                            {decodedContent || t.noData}
                                        </Text>
                                    </View>
                                )}
                            </ScrollView>
                        </ScrollView>
                    ) : (
                        <ScrollView style={s.fullscreenScroll} contentContainerStyle={s.fullscreenScrollContent}>
                            {viewMode === 'preview' ? (
                                <ScrollView horizontal showsHorizontalScrollIndicator contentContainerStyle={{ flexGrow: 1 }}>
                                    <View style={{ padding: 16 }}>
                                        <CodeHighlighter
                                            code={decodedContent || t.noData}
                                            extension={(viewingFile || '').split('.').pop() || ''}
                                            colors={colors}
                                        />
                                    </View>
                                </ScrollView>
                            ) : (
                                <ScrollView horizontal showsHorizontalScrollIndicator>
                                    <View style={s.fileContentTextContainer}>
                                        <Text style={[s.fileContentText, { color: colors.text }]} selectable>
                                            {decodedContent || t.noData}
                                        </Text>
                                    </View>
                                </ScrollView>
                            )}
                        </ScrollView>
                    )}
                </View>
            </Modal>
        </>
    );
}

function makeStyles(colors: ThemeColors) {
    return StyleSheet.create({
        container: { flex: 1, backgroundColor: colors.background },
        content: { paddingHorizontal: 16, paddingTop: 16 },
        repoHeader: { backgroundColor: colors.surface, borderRadius: 18, padding: 18, borderWidth: 1, borderColor: colors.border, marginBottom: 16, gap: 8 },
        repoTitleRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
        repoFullName: { fontSize: 18, fontWeight: '700' as const, color: colors.text, flex: 1 },
        repoDesc: { fontSize: 13, color: colors.textSecondary, lineHeight: 18 },
        repoMetaRow: { flexDirection: 'row', alignItems: 'center', gap: 14, marginTop: 4 },
        repoMetaItem: { flexDirection: 'row', alignItems: 'center', gap: 4 },
        repoMetaText: { fontSize: 12, color: colors.textMuted, fontWeight: '500' as const },
        langDot: { width: 8, height: 8, borderRadius: 4 },
        repoInfoRow: { flexDirection: 'row', alignItems: 'center', gap: 6, marginTop: 4 },
        repoInfoLabel: { fontSize: 12, color: colors.textMuted },
        repoInfoSep: { fontSize: 12, color: colors.textMuted },
        branchBadge: { flexDirection: 'row', alignItems: 'center', gap: 4, backgroundColor: GITEA_COLOR + '15', paddingHorizontal: 8, paddingVertical: 3, borderRadius: 8 },
        branchBadgeText: { fontSize: 11, color: GITEA_COLOR, fontWeight: '600' as const },
        tabBar: { flexDirection: 'row', backgroundColor: colors.surface, borderRadius: 14, borderWidth: 1, borderColor: colors.border, padding: 4, marginBottom: 16, gap: 2 },
        tab: { flex: 1, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', paddingVertical: 10, borderRadius: 10, gap: 5 },
        tabActive: { backgroundColor: GITEA_COLOR + '15' },
        tabText: { fontSize: 12, color: colors.textMuted, fontWeight: '600' as const },
        tabTextActive: { color: GITEA_COLOR },
        tabContent: { minHeight: 100 },
        backPathRow: { flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 12, paddingVertical: 8, paddingHorizontal: 12, backgroundColor: colors.surface, borderRadius: 10, borderWidth: 1, borderColor: colors.border },
        backPathText: { fontSize: 13, color: GITEA_COLOR, fontWeight: '500' as const, flex: 1 },
        emptyState: { alignItems: 'center', paddingVertical: 40, gap: 10 },
        emptyText: { fontSize: 14, color: colors.textMuted },
        fileList: { backgroundColor: colors.surface, borderRadius: 16, borderWidth: 1, borderColor: colors.border, overflow: 'hidden' },
        fileItem: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 16, paddingVertical: 13, gap: 12 },
        fileItemBorder: { borderBottomWidth: 1, borderBottomColor: colors.border },
        fileName: { flex: 1, fontSize: 14, color: colors.text, fontWeight: '500' as const },
        fileSize: { fontSize: 11, color: colors.textMuted },
        fileContentLoading: { alignItems: 'center', paddingVertical: 40, gap: 10 },
        loadingFileText: { fontSize: 13, color: colors.textMuted },
        fileContentError: { alignItems: 'center', paddingVertical: 40, gap: 10 },
        fileContentErrorText: { fontSize: 14, color: colors.stopped },
        fileContentCard: { backgroundColor: colors.surface, borderRadius: 16, borderWidth: 1, borderColor: colors.border, overflow: 'hidden' },
        fileContentHeader: { flexDirection: 'row', alignItems: 'center', gap: 8, paddingHorizontal: 16, paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: colors.border, backgroundColor: colors.surfaceHover },
        fileContentTitle: { flex: 1, fontSize: 13, fontWeight: '600' as const, color: colors.text },
        fileContentSize: { fontSize: 11, color: colors.textMuted },
        fileActionBtn: { padding: 6 },
        fileContentScroll: { maxHeight: 500 },
        fileImageContainer: { alignItems: 'center', justifyContent: 'center' },
        fileImage: { borderRadius: 12 },
        fileContentTextContainer: { minWidth: '100%', padding: 16 },
        fileContentText: { fontFamily: 'monospace', fontSize: 13, lineHeight: 20, color: colors.text },
        commitList: { backgroundColor: colors.surface, borderRadius: 16, borderWidth: 1, borderColor: colors.border, overflow: 'hidden', paddingLeft: 8 },
        commitItem: { flexDirection: 'row', paddingVertical: 14, paddingRight: 16, gap: 12 },
        commitItemBorder: { borderBottomWidth: 1, borderBottomColor: colors.border },
        commitDotLine: { alignItems: 'center', width: 20, paddingTop: 4 },
        commitDot: { width: 10, height: 10, borderRadius: 5, backgroundColor: GITEA_COLOR },
        commitLine: { width: 2, flex: 1, backgroundColor: colors.border, marginTop: 4 },
        commitContent: { flex: 1 },
        commitMessage: { fontSize: 14, color: colors.text, fontWeight: '500' as const, lineHeight: 20 },
        commitMeta: { flexDirection: 'row', alignItems: 'center', gap: 8, marginTop: 4 },
        commitAuthor: { fontSize: 12, color: colors.textSecondary, fontWeight: '500' as const },
        commitDate: { fontSize: 11, color: colors.textMuted },
        commitSha: { fontSize: 11, color: GITEA_COLOR, fontWeight: '600' as const, marginTop: 4 },
        issueList: { backgroundColor: colors.surface, borderRadius: 16, borderWidth: 1, borderColor: colors.border, overflow: 'hidden' },
        issueItem: { flexDirection: 'row', paddingHorizontal: 16, paddingVertical: 14, gap: 12 },
        issueItemBorder: { borderBottomWidth: 1, borderBottomColor: colors.border },
        issueIconWrap: { width: 32, height: 32, borderRadius: 10, alignItems: 'center', justifyContent: 'center', marginTop: 2 },
        issueContent: { flex: 1 },
        issueTitle: { fontSize: 14, color: colors.text, fontWeight: '500' as const, lineHeight: 20 },
        issueMeta: { flexDirection: 'row', alignItems: 'center', gap: 8, marginTop: 4 },
        issueAuthor: { fontSize: 12, color: colors.textSecondary },
        issueDate: { fontSize: 11, color: colors.textMuted },
        issueComments: { fontSize: 11, color: colors.textMuted },
        labelsRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 4, marginTop: 6 },
        labelBadge: { paddingHorizontal: 8, paddingVertical: 2, borderRadius: 8 },
        labelText: { fontSize: 10, fontWeight: '600' as const },
        branchList: { backgroundColor: colors.surface, borderRadius: 16, borderWidth: 1, borderColor: colors.border, overflow: 'hidden' },
        branchItem: { flexDirection: 'row', paddingHorizontal: 16, paddingVertical: 14, gap: 12, alignItems: 'center' },
        branchItemBorder: { borderBottomWidth: 1, borderBottomColor: colors.border },
        branchIcon: { width: 36, height: 36, borderRadius: 10, alignItems: 'center', justifyContent: 'center' },
        branchContent: { flex: 1 },
        branchNameRow: { flexDirection: 'row', alignItems: 'center', gap: 6, flex: 1, paddingRight: 8 },
        branchName: { fontSize: 14, color: colors.text, fontWeight: '600' as const },
        protectedBadge: { padding: 2 },
        defaultBadge: { backgroundColor: GITEA_COLOR + '18', paddingHorizontal: 6, paddingVertical: 2, borderRadius: 6 },
        defaultBadgeText: { fontSize: 10, color: GITEA_COLOR, fontWeight: '600' as const },
        branchCommit: { fontSize: 12, color: colors.textMuted, marginTop: 3 },
        branchSelectorBtn: { flexDirection: 'row', alignItems: 'center', gap: 6, backgroundColor: GITEA_COLOR + '15', paddingHorizontal: 10, paddingVertical: 4, borderRadius: 8, maxWidth: 160 },
        segmentControl: { flexDirection: 'row', backgroundColor: colors.surfaceHover, borderRadius: 10, padding: 4, marginBottom: 16, borderWidth: 1, borderColor: colors.border },
        segmentBtn: { flex: 1, paddingVertical: 8, alignItems: 'center', borderRadius: 8 },
        segmentBtnActive: { backgroundColor: colors.surface, shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.1, shadowRadius: 2, elevation: 2 },
        segmentBtnText: { fontSize: 13, color: colors.textSecondary, fontWeight: '500' as const },
        segmentBtnTextActive: { color: GITEA_COLOR, fontWeight: '600' as const },
        fileMarkdownContainer: { padding: 16 },
        readmeCard: { backgroundColor: colors.surface, borderRadius: 16, borderWidth: 1, borderColor: colors.border, marginTop: 16, overflow: 'hidden' },
        readmeHeader: { flexDirection: 'row', alignItems: 'center', gap: 8, paddingHorizontal: 16, paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: colors.border, backgroundColor: colors.surfaceHover },
        readmeTitle: { fontSize: 14, fontWeight: '600' as const, color: colors.text },
        readmeContent: { padding: 16 },
        modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'flex-end' },
        modalContent: { borderTopLeftRadius: 24, borderTopRightRadius: 24, maxHeight: '80%', paddingBottom: 40 },
        modalHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 20, paddingVertical: 16, borderBottomWidth: 1, borderBottomColor: colors.border },
        modalTitle: { fontSize: 18, fontWeight: '700' as const },
        modalCloseBtn: { padding: 4 },
        modalScroll: { padding: 16, paddingBottom: 40 },
        modalBranchItem: { flexDirection: 'row', alignItems: 'center', gap: 12, paddingVertical: 14, paddingHorizontal: 16, borderRadius: 12, marginBottom: 8 },
        modalBranchText: { fontSize: 15, fontWeight: '500' as const, flex: 1 },
        fullscreenContainer: { flex: 1 },
        fullscreenHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 16, paddingVertical: 14, paddingTop: 60, borderBottomWidth: 1 },
        fullscreenHeaderLeft: { flexDirection: 'row', alignItems: 'center', gap: 8, flex: 1, marginRight: 12 },
        fullscreenTitle: { fontSize: 16, fontWeight: '600' as const, flex: 1 },
        fullscreenActions: { flexDirection: 'row', alignItems: 'center', gap: 8 },
        fullscreenScroll: { flex: 1 },
        fullscreenScrollContent: { padding: 16 },
    });
}

