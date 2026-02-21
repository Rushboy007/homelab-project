export type Language = 'it' | 'en' | 'fr' | 'es' | 'de';

export interface Translations {
    loading: string;
    error: string;
    cancel: string;
    save: string;
    confirm: string;
    delete: string;
    back: string;
    close: string;
    copy: string;
    yes: string;
    no: string;
    noData: string;
    retry: string;

    tabHome: string;
    tabSettings: string;

    launcherTitle: string;
    launcherSubtitle: string;
    launcherConnected: string;
    launcherNotConfigured: string;
    launcherTapToConnect: string;
    launcherServices: string;

    statusUnreachable: string;
    statusVerifying: string;
    actionReconnect: string;

    greetingMorning: string;
    greetingAfternoon: string;
    greetingEvening: string;
    summaryTitle: string;
    summaryQueryTotal: string;
    summarySystemsOnline: string;

    servicePortainer: string;
    servicePihole: string;
    serviceBeszel: string;
    serviceGitea: string;
    servicePortainerDesc: string;
    servicePiholeDesc: string;
    serviceBeszelDesc: string;
    serviceGiteaDesc: string;

    loginTitle: string;
    loginSubtitle: string;
    loginUrl: string;
    loginUrlPlaceholder: string;
    loginUsername: string;
    loginEmail: string;
    loginPassword: string;
    loginConnect: string;
    loginConnecting: string;
    loginErrorUrl: string;
    loginErrorCredentials: string;
    loginErrorFailed: string;
    loginHintPihole: string;
    loginHintGitea2FA: string;

    portainerDashboard: string;
    portainerEndpoints: string;
    portainerActive: string;
    portainerContainers: string;
    portainerResources: string;
    portainerTotal: string;
    portainerRunning: string;
    portainerStopped: string;
    portainerImages: string;
    portainerVolumes: string;
    portainerCpus: string;
    portainerMemory: string;
    portainerViewAll: string;
    portainerSelectEndpoint: string;
    portainerServerInfo: string;
    portainerOnline: string;
    portainerOffline: string;
    portainerStacks: string;
    portainerHealthy: string;
    portainerUnhealthy: string;

    containersSearch: string;
    containersAll: string;
    containersRunning: string;
    containersStopped: string;
    containersEmpty: string;
    containersNoEndpoint: string;

    actionStart: string;
    actionStop: string;
    actionRestart: string;
    actionPause: string;
    actionResume: string;
    actionRemove: string;
    actionKill: string;
    actionConfirm: string;
    actionConfirmMessage: string;
    actionRemoveConfirm: string;
    actionRemoveMessage: string;

    detailInfo: string;
    detailStats: string;
    detailLogs: string;
    detailEnv: string;
    detailCompose: string;
    detailContainer: string;
    detailCreated: string;
    detailHostname: string;
    detailWorkDir: string;
    detailCommand: string;
    detailNetwork: string;
    detailMode: string;
    detailMounts: string;
    detailRestartPolicy: string;
    detailPolicy: string;
    detailMaxRetries: string;
    detailUptime: string;
    detailNotRunning: string;
    detailNoLogs: string;
    detailEnvVars: string;
    detailCpu: string;
    detailMemory: string;
    detailNetworkIO: string;
    detailUsed: string;
    detailContainerLogs: string;
    detailNotFound: string;
    detailComposeFile: string;
    detailComposeNotAvailable: string;
    detailComposeSave: string;
    detailComposeSaved: string;
    detailComposeSaveError: string;
    detailComposeLoading: string;

    piholeBlocking: string;
    piholeEnabled: string;
    piholeDisabled: string;
    piholeTotalQueries: string;
    piholeBlockedQueries: string;
    piholePercentBlocked: string;
    piholeTopBlocked: string;
    piholeTopDomains: string;
    piholeClients: string;
    piholeDomains: string;
    piholeGravity: string;
    piholeToggle: string;
    piholeQueries: string;
    piholeCached: string;
    piholeForwarded: string;
    piholeUniqueDomains: string;
    piholeBlockingWarningTitle: string;
    piholeBlockingWarningEnable: string;
    piholeBlockingWarningDisable: string;
    piholeBlockingDesc: string;
    piholeDisableDesc: string;
    piholeGravityUpdated: string;
    piholeOverview: string;
    piholeQueryActivity: string;

    beszelSystems: string;
    beszelUp: string;
    beszelDown: string;
    beszelCpu: string;
    beszelMemory: string;
    beszelDisk: string;
    beszelNetwork: string;
    beszelUptime: string;
    beszelNoSystems: string;
    beszelSystemDetail: string;
    beszelOs: string;
    beszelKernel: string;
    beszelHostname: string;
    beszelCpuModel: string;
    beszelTotalMemory: string;
    beszelUsedMemory: string;
    beszelTotalDisk: string;
    beszelUsedDisk: string;
    beszelNetworkSent: string;
    beszelNetworkReceived: string;
    beszelRefreshRate: string;
    beszelCores: string;
    beszelSystemInfo: string;
    beszelResources: string;
    beszelNetworkTraffic: string;

    giteaRepos: string;
    giteaOrgs: string;
    giteaStars: string;
    giteaForks: string;
    giteaIssues: string;
    giteaPrivate: string;
    giteaPublic: string;
    giteaNoRepos: string;
    giteaLanguage: string;
    gitea2FAHint: string;
    gitea2FAHintMessage: string;
    giteaFiles: string;
    giteaCommits: string;
    giteaBranches: string;
    giteaNoFiles: string;
    giteaNoCommits: string;
    giteaNoIssues: string;
    giteaOpenIssues: string;
    giteaClosedIssues: string;
    giteaDefaultBranch: string;
    giteaSize: string;
    giteaLastUpdate: string;
    giteaReadme: string;
    giteaOk: string;
    giteaContributions: string;
    giteaFileContent: string;
    giteaLessActive: string;
    giteaMoreActive: string;
    giteaMyForks: string;
    giteaPreview: string;
    giteaCode: string;

    beszelContainers: string;
    beszelNoContainers: string;

    piholeQueriesOverTime: string;

    settingsPreferences: string;
    settingsLanguage: string;
    settingsTheme: string;
    settingsThemeLight: string;
    settingsThemeDark: string;
    settingsItalian: string;
    settingsEnglish: string;
    settingsFrench: string;
    settingsSpanish: string;
    settingsGerman: string;
    settingsServices: string;
    settingsDisconnect: string;
    settingsDisconnectConfirm: string;
    settingsDisconnectMessage: string;
    settingsAbout: string;
    settingsVersion: string;
    settingsConnected: string;
    settingsNotConnected: string;
}

const it: Translations = {
    loading: 'Caricamento...',
    error: 'Errore',
    cancel: 'Annulla',
    save: 'Salva',
    confirm: 'Conferma',
    delete: 'Elimina',
    back: 'Indietro',
    close: 'Chiudi',
    copy: 'Copia',
    yes: 'Sì',
    no: 'No',
    noData: 'Nessun dato',
    retry: 'Riprova',

    tabHome: 'Home',
    tabSettings: 'Impostazioni',

    launcherTitle: 'HomeLab',
    launcherSubtitle: 'Il tuo pannello di controllo',
    launcherConnected: 'Connesso',
    launcherNotConfigured: 'Non configurato',
    launcherTapToConnect: 'Tocca per connettere',
    launcherServices: 'Servizi',

    statusUnreachable: 'Non raggiungibile',
    statusVerifying: 'Verifica...',
    actionReconnect: 'Riconnetti',

    greetingMorning: 'Buongiorno',
    greetingAfternoon: 'Buon pomeriggio',
    greetingEvening: 'Buonasera',
    summaryTitle: 'Riepilogo',
    summaryQueryTotal: 'Query Totali',
    summarySystemsOnline: 'Sistemi Online',

    servicePortainer: 'Portainer',
    servicePihole: 'Pi-hole',
    serviceBeszel: 'Beszel',
    serviceGitea: 'Gitea',
    servicePortainerDesc: 'Gestione container Docker',
    servicePiholeDesc: 'Blocco pubblicità di rete',
    serviceBeszelDesc: 'Monitoraggio server',
    serviceGiteaDesc: 'Hosting Git self-hosted',

    loginTitle: 'Connetti',
    loginSubtitle: 'Inserisci le credenziali del servizio',
    loginUrl: 'URL Server',
    loginUrlPlaceholder: 'https://servizio.esempio.com',
    loginUsername: 'Nome utente',
    loginEmail: 'Email',
    loginPassword: 'Password',
    loginConnect: 'Connetti',
    loginConnecting: 'Connessione...',
    loginErrorUrl: 'Inserisci l\'URL del server',
    loginErrorCredentials: 'Inserisci le credenziali',
    loginErrorFailed: 'Connessione fallita',
    loginHintPihole: 'Usa la password configurata nelle impostazioni di Pi-hole (Impostazioni → API / Web Interface → Password API)',
    loginHintGitea2FA: 'Se hai l\'autenticazione a due fattori attiva, genera una password app da Impostazioni → Applicazioni nel tuo Gitea.',

    portainerDashboard: 'Portainer',
    portainerEndpoints: 'Endpoint',
    portainerActive: 'Attivo',
    portainerContainers: 'Container',
    portainerResources: 'Risorse',
    portainerTotal: 'Totali',
    portainerRunning: 'Attivi',
    portainerStopped: 'Fermati',
    portainerImages: 'Immagini',
    portainerVolumes: 'Volumi',
    portainerCpus: 'CPU',
    portainerMemory: 'Memoria',
    portainerViewAll: 'Tutti i container',
    portainerSelectEndpoint: 'Seleziona un endpoint',
    portainerServerInfo: 'Info Server',
    portainerOnline: 'Online',
    portainerOffline: 'Offline',
    portainerStacks: 'Stack',
    portainerHealthy: 'Healthy',
    portainerUnhealthy: 'Unhealthy',

    containersSearch: 'Cerca container...',
    containersAll: 'Tutti',
    containersRunning: 'Attivi',
    containersStopped: 'Fermati',
    containersEmpty: 'Nessun container trovato',
    containersNoEndpoint: 'Seleziona prima un endpoint',

    actionStart: 'Avvia',
    actionStop: 'Ferma',
    actionRestart: 'Riavvia',
    actionPause: 'Pausa',
    actionResume: 'Riprendi',
    actionRemove: 'Rimuovi',
    actionKill: 'Termina',
    actionConfirm: 'Conferma Azione',
    actionConfirmMessage: 'Sei sicuro di voler eseguire questa azione?',
    actionRemoveConfirm: 'Rimuovi Container',
    actionRemoveMessage: 'Questa azione è irreversibile. Continuare?',

    detailInfo: 'Info',
    detailStats: 'Stats',
    detailLogs: 'Log',
    detailEnv: 'Env',
    detailCompose: 'Compose',
    detailContainer: 'Container',
    detailCreated: 'Creato',
    detailHostname: 'Hostname',
    detailWorkDir: 'Dir Lavoro',
    detailCommand: 'Comando',
    detailNetwork: 'Rete',
    detailMode: 'Modalità',
    detailMounts: 'Volumi',
    detailRestartPolicy: 'Policy Riavvio',
    detailPolicy: 'Policy',
    detailMaxRetries: 'Max Tentativi',
    detailUptime: 'Uptime',
    detailNotRunning: 'Il container non è in esecuzione',
    detailNoLogs: 'Nessun log disponibile',
    detailEnvVars: 'Variabili d\'Ambiente',
    detailCpu: 'CPU',
    detailMemory: 'Memoria',
    detailNetworkIO: 'I/O Rete',
    detailUsed: 'utilizzato',
    detailContainerLogs: 'Log Container',
    detailNotFound: 'Container non trovato',
    detailComposeFile: 'File Docker Compose',
    detailComposeNotAvailable: 'Docker Compose non disponibile per questo container',
    detailComposeSave: 'Salva Modifiche',
    detailComposeSaved: 'Compose salvato con successo',
    detailComposeSaveError: 'Errore nel salvataggio del compose',
    detailComposeLoading: 'Caricamento compose...',

    piholeBlocking: 'Blocco Annunci',
    piholeEnabled: 'Attivo',
    piholeDisabled: 'Disattivo',
    piholeTotalQueries: 'Query Totali',
    piholeBlockedQueries: 'Query Bloccate',
    piholePercentBlocked: '% Bloccata',
    piholeTopBlocked: 'Più Bloccati',
    piholeTopDomains: 'Domini Principali',
    piholeClients: 'Client Principali',
    piholeDomains: 'Domini',
    piholeGravity: 'Domini in Gravity',
    piholeToggle: 'Attiva/Disattiva Blocco',
    piholeQueries: 'Statistiche Query',
    piholeCached: 'In Cache',
    piholeForwarded: 'Inoltrate',
    piholeUniqueDomains: 'Domini Unici',
    piholeBlockingWarningTitle: 'Blocco Annunci',
    piholeBlockingWarningEnable: 'Vuoi riattivare il blocco degli annunci? Tutte le query DNS verranno nuovamente filtrate attraverso le liste di blocco.',
    piholeBlockingWarningDisable: 'Vuoi disattivare il blocco degli annunci? Tutti gli annunci e i tracker saranno temporaneamente consentiti. Le query DNS non verranno più filtrate.',
    piholeBlockingDesc: 'Il blocco DNS è attivo. Annunci, tracker e domini malevoli vengono filtrati automaticamente.',
    piholeDisableDesc: 'Il blocco DNS è disattivato. Tutto il traffico passa senza filtri.',
    piholeGravityUpdated: 'Ultimo aggiornamento Gravity',
    piholeOverview: 'Panoramica',
    piholeQueryActivity: 'Attività Query',

    beszelSystems: 'Sistemi',
    beszelUp: 'Online',
    beszelDown: 'Offline',
    beszelCpu: 'CPU',
    beszelMemory: 'Memoria',
    beszelDisk: 'Disco',
    beszelNetwork: 'Rete',
    beszelUptime: 'Uptime',
    beszelNoSystems: 'Nessun sistema trovato',
    beszelSystemDetail: 'Dettagli Sistema',
    beszelOs: 'Sistema Operativo',
    beszelKernel: 'Kernel',
    beszelHostname: 'Hostname',
    beszelCpuModel: 'Modello CPU',
    beszelTotalMemory: 'Memoria Totale',
    beszelUsedMemory: 'Memoria Usata',
    beszelTotalDisk: 'Disco Totale',
    beszelUsedDisk: 'Disco Usato',
    beszelNetworkSent: 'Inviati',
    beszelNetworkReceived: 'Ricevuti',
    beszelRefreshRate: 'Aggiornamento ogni 15s',
    beszelCores: 'Core',
    beszelSystemInfo: 'Informazioni Sistema',
    beszelResources: 'Risorse',
    beszelNetworkTraffic: 'Traffico di Rete',

    giteaRepos: 'Repository',
    giteaOrgs: 'Organizzazioni',
    giteaStars: 'Stelle',
    giteaForks: 'Fork',
    giteaIssues: 'Issue',
    giteaPrivate: 'Privato',
    giteaPublic: 'Pubblico',
    giteaNoRepos: 'Nessun repository trovato',
    giteaLanguage: 'Linguaggio',
    gitea2FAHint: 'Autenticazione a Due Fattori',
    gitea2FAHintMessage: 'Se hai l\'autenticazione a due fattori (2FA) attiva su Gitea, dovrai generare una password applicazione. Vai su Impostazioni → Applicazioni nel tuo Gitea per crearla, poi usa quella come password qui.',
    giteaFiles: 'File',
    giteaCommits: 'Commit',
    giteaBranches: 'Branch',
    giteaNoFiles: 'Nessun file',
    giteaNoCommits: 'Nessun commit',
    giteaNoIssues: 'Nessuna issue',
    giteaOpenIssues: 'Aperte',
    giteaClosedIssues: 'Chiuse',
    giteaDefaultBranch: 'Branch Predefinito',
    giteaSize: 'Dimensione',
    giteaLastUpdate: 'Ultimo Aggiornamento',
    giteaReadme: 'README',
    giteaOk: 'Ho capito',
    giteaContributions: 'Contribuzioni',
    giteaFileContent: 'Contenuto File',
    giteaLessActive: 'Meno',
    giteaMoreActive: 'Più',
    giteaMyForks: 'Fork (Miei)',
    giteaPreview: 'Anteprima',
    giteaCode: 'Codice',

    beszelContainers: 'Container',
    beszelNoContainers: 'Nessun container',

    piholeQueriesOverTime: 'Query nel Tempo',

    settingsPreferences: 'Preferenze',
    settingsLanguage: 'Lingua',
    settingsTheme: 'Tema',
    settingsThemeLight: 'Chiaro',
    settingsThemeDark: 'Scuro',
    settingsItalian: 'Italiano',
    settingsEnglish: 'English',
    settingsFrench: 'Français',
    settingsSpanish: 'Español',
    settingsGerman: 'Deutsch',
    settingsServices: 'Servizi Configurati',
    settingsDisconnect: 'Disconnetti',
    settingsDisconnectConfirm: 'Disconnetti',
    settingsDisconnectMessage: 'Sei sicuro di volerti disconnettere da questo servizio?',
    settingsAbout: 'Info',
    settingsVersion: 'Versione',
    settingsConnected: 'Connesso',
    settingsNotConnected: 'Non connesso',
};

const en: Translations = {
    loading: 'Loading...',
    error: 'Error',
    cancel: 'Cancel',
    save: 'Save',
    confirm: 'Confirm',
    delete: 'Delete',
    back: 'Back',
    close: 'Close',
    copy: 'Copy',
    yes: 'Yes',
    no: 'No',
    noData: 'No data',
    retry: 'Retry',

    tabHome: 'Home',
    tabSettings: 'Settings',

    launcherTitle: 'HomeLab',
    launcherSubtitle: 'Your control panel',
    launcherConnected: 'Connected',
    launcherNotConfigured: 'Not configured',
    launcherTapToConnect: 'Tap to connect',
    launcherServices: 'Services',

    statusUnreachable: 'Unreachable',
    statusVerifying: 'Verifying...',
    actionReconnect: 'Reconnect',

    greetingMorning: 'Good morning',
    greetingAfternoon: 'Good afternoon',
    greetingEvening: 'Good evening',
    summaryTitle: 'Summary',
    summaryQueryTotal: 'Total Queries',
    summarySystemsOnline: 'Systems Online',

    servicePortainer: 'Portainer',
    servicePihole: 'Pi-hole',
    serviceBeszel: 'Beszel',
    serviceGitea: 'Gitea',
    servicePortainerDesc: 'Docker container management',
    servicePiholeDesc: 'Network-wide ad blocking',
    serviceBeszelDesc: 'Server monitoring',
    serviceGiteaDesc: 'Self-hosted Git hosting',

    loginTitle: 'Connect',
    loginSubtitle: 'Enter service credentials',
    loginUrl: 'Server URL',
    loginUrlPlaceholder: 'https://service.example.com',
    loginUsername: 'Username',
    loginEmail: 'Email',
    loginPassword: 'Password',
    loginConnect: 'Connect',
    loginConnecting: 'Connecting...',
    loginErrorUrl: 'Enter the server URL',
    loginErrorCredentials: 'Enter credentials',
    loginErrorFailed: 'Connection failed',
    loginHintPihole: 'Use the password configured in Pi-hole settings (Settings → API / Web Interface → API Password)',
    loginHintGitea2FA: 'If you have two-factor auth enabled, generate an app password from Settings → Applications in your Gitea.',

    portainerDashboard: 'Portainer',
    portainerEndpoints: 'Endpoints',
    portainerActive: 'Active',
    portainerContainers: 'Containers',
    portainerResources: 'Resources',
    portainerTotal: 'Total',
    portainerRunning: 'Running',
    portainerStopped: 'Stopped',
    portainerImages: 'Images',
    portainerVolumes: 'Volumes',
    portainerCpus: 'CPUs',
    portainerMemory: 'Memory',
    portainerViewAll: 'All containers',
    portainerSelectEndpoint: 'Select an endpoint',
    portainerServerInfo: 'Server Info',
    portainerOnline: 'Online',
    portainerOffline: 'Offline',
    portainerStacks: 'Stacks',
    portainerHealthy: 'Healthy',
    portainerUnhealthy: 'Unhealthy',

    containersSearch: 'Search containers...',
    containersAll: 'All',
    containersRunning: 'Running',
    containersStopped: 'Stopped',
    containersEmpty: 'No containers found',
    containersNoEndpoint: 'Select an endpoint first',

    actionStart: 'Start',
    actionStop: 'Stop',
    actionRestart: 'Restart',
    actionPause: 'Pause',
    actionResume: 'Resume',
    actionRemove: 'Remove',
    actionKill: 'Kill',
    actionConfirm: 'Confirm Action',
    actionConfirmMessage: 'Are you sure you want to perform this action?',
    actionRemoveConfirm: 'Remove Container',
    actionRemoveMessage: 'This action is irreversible. Continue?',

    detailInfo: 'Info',
    detailStats: 'Stats',
    detailLogs: 'Logs',
    detailEnv: 'Env',
    detailCompose: 'Compose',
    detailContainer: 'Container',
    detailCreated: 'Created',
    detailHostname: 'Hostname',
    detailWorkDir: 'WorkDir',
    detailCommand: 'Command',
    detailNetwork: 'Network',
    detailMode: 'Mode',
    detailMounts: 'Mounts',
    detailRestartPolicy: 'Restart Policy',
    detailPolicy: 'Policy',
    detailMaxRetries: 'Max Retries',
    detailUptime: 'Uptime',
    detailNotRunning: 'Container is not running',
    detailNoLogs: 'No logs available',
    detailEnvVars: 'Environment Variables',
    detailCpu: 'CPU',
    detailMemory: 'Memory',
    detailNetworkIO: 'Network I/O',
    detailUsed: 'used',
    detailContainerLogs: 'Container Logs',
    detailNotFound: 'Container not found',
    detailComposeFile: 'Docker Compose File',
    detailComposeNotAvailable: 'Docker Compose not available for this container',
    detailComposeSave: 'Save Changes',
    detailComposeSaved: 'Compose saved successfully',
    detailComposeSaveError: 'Error saving compose file',
    detailComposeLoading: 'Loading compose...',

    piholeBlocking: 'Ad Blocking',
    piholeEnabled: 'Enabled',
    piholeDisabled: 'Disabled',
    piholeTotalQueries: 'Total Queries',
    piholeBlockedQueries: 'Blocked Queries',
    piholePercentBlocked: '% Blocked',
    piholeTopBlocked: 'Top Blocked',
    piholeTopDomains: 'Top Domains',
    piholeClients: 'Top Clients',
    piholeDomains: 'Domains',
    piholeGravity: 'Gravity Domains',
    piholeToggle: 'Toggle Blocking',
    piholeQueries: 'Query Statistics',
    piholeCached: 'Cached',
    piholeForwarded: 'Forwarded',
    piholeUniqueDomains: 'Unique Domains',
    piholeBlockingWarningTitle: 'Ad Blocking',
    piholeBlockingWarningEnable: 'Do you want to re-enable ad blocking? All DNS queries will be filtered through blocklists again.',
    piholeBlockingWarningDisable: 'Do you want to disable ad blocking? All ads and trackers will be temporarily allowed. DNS queries will no longer be filtered.',
    piholeBlockingDesc: 'DNS blocking is active. Ads, trackers and malicious domains are automatically filtered.',
    piholeDisableDesc: 'DNS blocking is disabled. All traffic passes without filtering.',
    piholeGravityUpdated: 'Last Gravity update',
    piholeOverview: 'Overview',
    piholeQueryActivity: 'Query Activity',

    beszelSystems: 'Systems',
    beszelUp: 'Online',
    beszelDown: 'Offline',
    beszelCpu: 'CPU',
    beszelMemory: 'Memory',
    beszelDisk: 'Disk',
    beszelNetwork: 'Network',
    beszelUptime: 'Uptime',
    beszelNoSystems: 'No systems found',
    beszelSystemDetail: 'System Details',
    beszelOs: 'Operating System',
    beszelKernel: 'Kernel',
    beszelHostname: 'Hostname',
    beszelCpuModel: 'CPU Model',
    beszelTotalMemory: 'Total Memory',
    beszelUsedMemory: 'Used Memory',
    beszelTotalDisk: 'Total Disk',
    beszelUsedDisk: 'Used Disk',
    beszelNetworkSent: 'Sent',
    beszelNetworkReceived: 'Received',
    beszelRefreshRate: 'Refreshes every 15s',
    beszelCores: 'Cores',
    beszelSystemInfo: 'System Information',
    beszelResources: 'Resources',
    beszelNetworkTraffic: 'Network Traffic',

    giteaRepos: 'Repositories',
    giteaOrgs: 'Organizations',
    giteaStars: 'Stars',
    giteaForks: 'Forks',
    giteaIssues: 'Issues',
    giteaPrivate: 'Private',
    giteaPublic: 'Public',
    giteaNoRepos: 'No repositories found',
    giteaLanguage: 'Language',
    gitea2FAHint: 'Two-Factor Authentication',
    gitea2FAHintMessage: 'If you have two-factor authentication (2FA) enabled on Gitea, you\'ll need to generate an app password. Go to Settings → Applications in your Gitea to create one, then use it as the password here.',
    giteaFiles: 'Files',
    giteaCommits: 'Commits',
    giteaBranches: 'Branches',
    giteaNoFiles: 'No files',
    giteaNoCommits: 'No commits',
    giteaNoIssues: 'No issues',
    giteaOpenIssues: 'Open',
    giteaClosedIssues: 'Closed',
    giteaDefaultBranch: 'Default Branch',
    giteaSize: 'Size',
    giteaLastUpdate: 'Last Update',
    giteaReadme: 'README',
    giteaOk: 'Got it',
    giteaContributions: 'Contributions',
    giteaFileContent: 'File Content',
    giteaLessActive: 'Less',
    giteaMoreActive: 'More',
    giteaMyForks: 'Forks (Mine)',
    giteaPreview: 'Preview',
    giteaCode: 'Code',

    beszelContainers: 'Containers',
    beszelNoContainers: 'No containers',

    piholeQueriesOverTime: 'Queries Over Time',

    settingsPreferences: 'Preferences',
    settingsLanguage: 'Language',
    settingsTheme: 'Theme',
    settingsThemeLight: 'Light',
    settingsThemeDark: 'Dark',
    settingsItalian: 'Italiano',
    settingsEnglish: 'English',
    settingsFrench: 'Français',
    settingsSpanish: 'Español',
    settingsGerman: 'Deutsch',
    settingsServices: 'Configured Services',
    settingsDisconnect: 'Disconnect',
    settingsDisconnectConfirm: 'Disconnect',
    settingsDisconnectMessage: 'Are you sure you want to disconnect from this service?',
    settingsAbout: 'About',
    settingsVersion: 'Version',
    settingsConnected: 'Connected',
    settingsNotConnected: 'Not connected',
};

const fr: Translations = {
    loading: 'Chargement...',
    error: 'Erreur',
    cancel: 'Annuler',
    save: 'Enregistrer',
    confirm: 'Confirmer',
    delete: 'Supprimer',
    back: 'Retour',
    close: 'Fermer',
    copy: 'Copier',
    yes: 'Oui',
    no: 'Non',
    noData: 'Aucune donnée',
    retry: 'Réessayer',

    tabHome: 'Accueil',
    tabSettings: 'Paramètres',

    launcherTitle: 'HomeLab',
    launcherSubtitle: 'Votre panneau de contrôle',
    launcherConnected: 'Connecté',
    launcherNotConfigured: 'Non configuré',
    launcherTapToConnect: 'Appuyez pour connecter',
    launcherServices: 'Services',

    statusUnreachable: 'Inaccessible',
    statusVerifying: 'Vérification...',
    actionReconnect: 'Reconnecter',

    greetingMorning: 'Bonjour',
    greetingAfternoon: 'Bon après-midi',
    greetingEvening: 'Bonsoir',
    summaryTitle: 'Résumé',
    summaryQueryTotal: 'Requêtes Totales',
    summarySystemsOnline: 'Systèmes en Ligne',

    servicePortainer: 'Portainer',
    servicePihole: 'Pi-hole',
    serviceBeszel: 'Beszel',
    serviceGitea: 'Gitea',
    servicePortainerDesc: 'Gestion de conteneurs Docker',
    servicePiholeDesc: 'Blocage de publicités réseau',
    serviceBeszelDesc: 'Surveillance de serveurs',
    serviceGiteaDesc: 'Hébergement Git auto-hébergé',

    loginTitle: 'Se connecter',
    loginSubtitle: 'Entrez les identifiants du service',
    loginUrl: 'URL du Serveur',
    loginUrlPlaceholder: 'https://service.exemple.com',
    loginUsername: 'Nom d\'utilisateur',
    loginEmail: 'E-mail',
    loginPassword: 'Mot de passe',
    loginConnect: 'Connecter',
    loginConnecting: 'Connexion...',
    loginErrorUrl: 'Entrez l\'URL du serveur',
    loginErrorCredentials: 'Entrez les identifiants',
    loginErrorFailed: 'Échec de la connexion',
    loginHintPihole: 'Utilisez le mot de passe configuré dans les paramètres de Pi-hole (Paramètres → API / Interface Web → Mot de passe API)',
    loginHintGitea2FA: 'Si vous avez activé l\'authentification à deux facteurs, générez un mot de passe d\'application depuis Paramètres → Applications dans votre Gitea.',

    portainerDashboard: 'Portainer',
    portainerEndpoints: 'Endpoints',
    portainerActive: 'Actif',
    portainerContainers: 'Conteneurs',
    portainerResources: 'Ressources',
    portainerTotal: 'Total',
    portainerRunning: 'En cours',
    portainerStopped: 'Arrêtés',
    portainerImages: 'Images',
    portainerVolumes: 'Volumes',
    portainerCpus: 'Processeurs (CPU)',
    portainerMemory: 'Mémoire',
    portainerViewAll: 'Tous les conteneurs',
    portainerSelectEndpoint: 'Sélectionnez un endpoint',
    portainerServerInfo: 'Info Serveur',
    portainerOnline: 'En ligne',
    portainerOffline: 'Hors ligne',
    portainerStacks: 'Piles (Stacks)',
    portainerHealthy: 'Sain',
    portainerUnhealthy: 'Malsain',

    containersSearch: 'Rechercher des conteneurs...',
    containersAll: 'Tous',
    containersRunning: 'En cours',
    containersStopped: 'Arrêtés',
    containersEmpty: 'Aucun conteneur trouvé',
    containersNoEndpoint: 'Sélectionnez d\'abord un endpoint',

    actionStart: 'Démarrer',
    actionStop: 'Arrêter',
    actionRestart: 'Redémarrer',
    actionPause: 'Mettre en pause',
    actionResume: 'Reprendre',
    actionRemove: 'Supprimer',
    actionKill: 'Tuer',
    actionConfirm: 'Confirmer l\'action',
    actionConfirmMessage: 'Êtes-vous sûr de vouloir effectuer cette action ?',
    actionRemoveConfirm: 'Supprimer le conteneur',
    actionRemoveMessage: 'Cette action est irréversible. Continuer ?',

    detailInfo: 'Info',
    detailStats: 'Stats',
    detailLogs: 'Journaux',
    detailEnv: 'Env',
    detailCompose: 'Composer',
    detailContainer: 'Conteneur',
    detailCreated: 'Créé',
    detailHostname: 'Nom d\'hôte',
    detailWorkDir: 'Rép de travail',
    detailCommand: 'Commande',
    detailNetwork: 'Réseau',
    detailMode: 'Mode',
    detailMounts: 'Montages',
    detailRestartPolicy: 'Politique de redémarrage',
    detailPolicy: 'Politique',
    detailMaxRetries: 'Tentatives max',
    detailUptime: 'Tps de fonct',
    detailNotRunning: 'Le conteneur n\'est pas en cours d\'exécution',
    detailNoLogs: 'Aucun journal disponible',
    detailEnvVars: 'Variables d\'environnement',
    detailCpu: 'Processeur (CPU)',
    detailMemory: 'Mémoire',
    detailNetworkIO: 'E/S Réseau',
    detailUsed: 'utilisé',
    detailContainerLogs: 'Journaux du Conteneur',
    detailNotFound: 'Conteneur introuvable',
    detailComposeFile: 'Fichier Docker Compose',
    detailComposeNotAvailable: 'Docker Compose n\'est pas disponible pour ce conteneur',
    detailComposeSave: 'Enregistrer les modifications',
    detailComposeSaved: 'Compose enregistré avec succès',
    detailComposeSaveError: 'Erreur lors de l\'enregistrement du compose',
    detailComposeLoading: 'Chargement de compose...',

    piholeBlocking: 'Blocage des pubs',
    piholeEnabled: 'Activé',
    piholeDisabled: 'Désactivé',
    piholeTotalQueries: 'Requêtes Totales',
    piholeBlockedQueries: 'Requêtes Bloquées',
    piholePercentBlocked: '% Bloqué',
    piholeTopBlocked: 'Top Bloqués',
    piholeTopDomains: 'Top Domaines',
    piholeClients: 'Top Clients',
    piholeDomains: 'Domaines',
    piholeGravity: 'Domaines Gravity',
    piholeToggle: 'Basculer le blocage',
    piholeQueries: 'Stats des Requêtes',
    piholeCached: 'En cache',
    piholeForwarded: 'Transférées',
    piholeUniqueDomains: 'Domaines uniques',
    piholeBlockingWarningTitle: 'Blocage des pubs',
    piholeBlockingWarningEnable: 'Voulez-vous réactiver le blocage des publicités ? Toutes les requêtes DNS seront à nouveau filtrées via les listes de blocage.',
    piholeBlockingWarningDisable: 'Voulez-vous désactiver le blocage des publicités ? Toutes les publicités et les trackers seront temporairement autorisés. Les requêtes DNS ne seront plus filtrées.',
    piholeBlockingDesc: 'Le blocage DNS est actif. Les pubs, les trackers et les domaines malveillants sont automatiquement filtrés.',
    piholeDisableDesc: 'Le blocage DNS est désactivé. Tout le trafic passe sans filtrage.',
    piholeGravityUpdated: 'Dernière mise à jour Gravity',
    piholeOverview: 'Aperçu',
    piholeQueryActivity: 'Activité des requêtes',

    beszelSystems: 'Systèmes',
    beszelUp: 'En ligne',
    beszelDown: 'Hors ligne',
    beszelCpu: 'Processeur',
    beszelMemory: 'Mémoire',
    beszelDisk: 'Disque',
    beszelNetwork: 'Réseau',
    beszelUptime: 'Tps fonct',
    beszelNoSystems: 'Aucun système trouvé',
    beszelSystemDetail: 'Détails du système',
    beszelOs: 'Système d\'Exploitation',
    beszelKernel: 'Noyau (Kernel)',
    beszelHostname: 'Nom d\'hôte',
    beszelCpuModel: 'Modèle CPU',
    beszelTotalMemory: 'Mémoire totale',
    beszelUsedMemory: 'Mémoire utilisée',
    beszelTotalDisk: 'Disque total',
    beszelUsedDisk: 'Disque utilisé',
    beszelNetworkSent: 'Envoyé',
    beszelNetworkReceived: 'Reçu',
    beszelRefreshRate: 'S\'actualise toutes les 15s',
    beszelCores: 'Cœurs',
    beszelSystemInfo: 'Informations système',
    beszelResources: 'Ressources',
    beszelNetworkTraffic: 'Trafic réseau',

    giteaRepos: 'Dépôts',
    giteaOrgs: 'Organisations',
    giteaStars: 'Étoiles',
    giteaForks: 'Forks (Bifurcations)',
    giteaIssues: 'Problèmes (Issues)',
    giteaPrivate: 'Privé',
    giteaPublic: 'Public',
    giteaNoRepos: 'Aucun dépôt trouvé',
    giteaLanguage: 'Langage',
    gitea2FAHint: 'Authentification à deux facteurs',
    gitea2FAHintMessage: 'Si vous avez activé l\'authentification à deux facteurs (2FA) sur Gitea, vous devrez générer un mot de passe d\'application. Allez dans Paramètres → Applications dans votre Gitea pour en créer un, puis utilisez ce mot de passe ici.',
    giteaFiles: 'Fichiers',
    giteaCommits: 'Commits',
    giteaBranches: 'Branches',
    giteaNoFiles: 'Aucun fichier',
    giteaNoCommits: 'Aucun commit',
    giteaNoIssues: 'Aucun problème',
    giteaOpenIssues: 'Ouverts',
    giteaClosedIssues: 'Fermés',
    giteaDefaultBranch: 'Branche par défaut',
    giteaSize: 'Taille',
    giteaLastUpdate: 'Dernière mise à jour',
    giteaReadme: 'LISEZMOI (README)',
    giteaOk: 'Compris',
    giteaContributions: 'Contributions',
    giteaFileContent: 'Contenu du Fichier',
    giteaLessActive: 'Moins',
    giteaMoreActive: 'Plus',
    giteaMyForks: 'Forks (Mes)',
    giteaPreview: 'Aperçu',
    giteaCode: 'Code',

    beszelContainers: 'Conteneurs',
    beszelNoContainers: 'Aucun conteneur',

    piholeQueriesOverTime: 'Requêtes au fil du temps',

    settingsPreferences: 'Préférences',
    settingsLanguage: 'Langue',
    settingsTheme: 'Thème',
    settingsThemeLight: 'Clair',
    settingsThemeDark: 'Sombre',
    settingsItalian: 'Italiano',
    settingsEnglish: 'English',
    settingsFrench: 'Français',
    settingsSpanish: 'Español',
    settingsGerman: 'Deutsch',
    settingsServices: 'Services Configurés',
    settingsDisconnect: 'Déconnecter',
    settingsDisconnectConfirm: 'Déconnecter',
    settingsDisconnectMessage: 'Êtes-vous sûr de vouloir vous déconnecter de ce service ?',
    settingsAbout: 'À propos',
    settingsVersion: 'Version',
    settingsConnected: 'Connecté',
    settingsNotConnected: 'Non connecté',
};

const es: Translations = {
    loading: 'Cargando...',
    error: 'Error',
    cancel: 'Cancelar',
    save: 'Guardar',
    confirm: 'Confirmar',
    delete: 'Eliminar',
    back: 'Atrás',
    close: 'Cerrar',
    copy: 'Copiar',
    yes: 'Sí',
    no: 'No',
    noData: 'Sin datos',
    retry: 'Reintentar',

    tabHome: 'Inicio',
    tabSettings: 'Ajustes',

    launcherTitle: 'HomeLab',
    launcherSubtitle: 'Tu panel de control',
    launcherConnected: 'Conectado',
    launcherNotConfigured: 'No configurado',
    launcherTapToConnect: 'Toca para conectar',
    launcherServices: 'Servicios',

    statusUnreachable: 'Inalcanzable',
    statusVerifying: 'Verificando...',
    actionReconnect: 'Reconectar',

    greetingMorning: 'Buenos días',
    greetingAfternoon: 'Buenas tardes',
    greetingEvening: 'Buenas noches',
    summaryTitle: 'Resumen',
    summaryQueryTotal: 'Consultas Totales',
    summarySystemsOnline: 'Sistemas en Línea',

    servicePortainer: 'Portainer',
    servicePihole: 'Pi-hole',
    serviceBeszel: 'Beszel',
    serviceGitea: 'Gitea',
    servicePortainerDesc: 'Gestión de contenedores Docker',
    servicePiholeDesc: 'Bloqueo de anuncios de red',
    serviceBeszelDesc: 'Monitorización de servidores',
    serviceGiteaDesc: 'Alojamiento Git auto-hospedado',

    loginTitle: 'Conectar',
    loginSubtitle: 'Introduce las credenciales del servicio',
    loginUrl: 'URL del Servidor',
    loginUrlPlaceholder: 'https://servicio.ejemplo.com',
    loginUsername: 'Nombre de usuario',
    loginEmail: 'Correo electrónico',
    loginPassword: 'Contraseña',
    loginConnect: 'Conectar',
    loginConnecting: 'Conectando...',
    loginErrorUrl: 'Introduce la URL del servidor',
    loginErrorCredentials: 'Introduce las credenciales',
    loginErrorFailed: 'Conexión fallida',
    loginHintPihole: 'Usa la contraseña configurada en los ajustes de Pi-hole (Ajustes → API / Interfaz Web → Contraseña de la API)',
    loginHintGitea2FA: 'Si tienes activada la autenticación de dos factores, genera una contraseña de aplicación en Ajustes → Aplicaciones en tu Gitea.',

    portainerDashboard: 'Portainer',
    portainerEndpoints: 'Endpoints',
    portainerActive: 'Activo',
    portainerContainers: 'Contenedores',
    portainerResources: 'Recursos',
    portainerTotal: 'Total',
    portainerRunning: 'En ejecución',
    portainerStopped: 'Detenidos',
    portainerImages: 'Imágenes',
    portainerVolumes: 'Volúmenes',
    portainerCpus: 'CPUs',
    portainerMemory: 'Memoria',
    portainerViewAll: 'Todos los contenedores',
    portainerSelectEndpoint: 'Selecciona un endpoint',
    portainerServerInfo: 'Info del Servidor',
    portainerOnline: 'En línea',
    portainerOffline: 'Fuera de línea',
    portainerStacks: 'Pilas (Stacks)',
    portainerHealthy: 'Sano',
    portainerUnhealthy: 'No sano',

    containersSearch: 'Buscar contenedores...',
    containersAll: 'Todos',
    containersRunning: 'En ejecución',
    containersStopped: 'Detenidos',
    containersEmpty: 'No se encontraron contenedores',
    containersNoEndpoint: 'Selecciona primero un endpoint',

    actionStart: 'Iniciar',
    actionStop: 'Detener',
    actionRestart: 'Reiniciar',
    actionPause: 'Pausar',
    actionResume: 'Reanudar',
    actionRemove: 'Eliminar',
    actionKill: 'Matar',
    actionConfirm: 'Confirmar Acción',
    actionConfirmMessage: '¿Estás seguro de que quieres realizar esta acción?',
    actionRemoveConfirm: 'Eliminar Contenedor',
    actionRemoveMessage: 'Esta acción es irreversible. ¿Continuar?',

    detailInfo: 'Info',
    detailStats: 'Estadísticas',
    detailLogs: 'Registros',
    detailEnv: 'Env',
    detailCompose: 'Componer',
    detailContainer: 'Contenedor',
    detailCreated: 'Creado',
    detailHostname: 'Nombre de host',
    detailWorkDir: 'Dir. de trabajo',
    detailCommand: 'Comando',
    detailNetwork: 'Red',
    detailMode: 'Modo',
    detailMounts: 'Montajes',
    detailRestartPolicy: 'Política de reinicio',
    detailPolicy: 'Política',
    detailMaxRetries: 'Intentos máx.',
    detailUptime: 'Tpo. de activ.',
    detailNotRunning: 'El contenedor no está en ejecución',
    detailNoLogs: 'No hay registros disponibles',
    detailEnvVars: 'Variables de entorno',
    detailCpu: 'CPU',
    detailMemory: 'Memoria',
    detailNetworkIO: 'E/S de Red',
    detailUsed: 'utilizado',
    detailContainerLogs: 'Registros del Contenedor',
    detailNotFound: 'Contenedor no encontrado',
    detailComposeFile: 'Archivo Docker Compose',
    detailComposeNotAvailable: 'Docker Compose no disponible para este contenedor',
    detailComposeSave: 'Guardar Cambios',
    detailComposeSaved: 'Compose guardado exitosamente',
    detailComposeSaveError: 'Error al guardar el archivo compose',
    detailComposeLoading: 'Cargando compose...',

    piholeBlocking: 'Bloqueo de anuncios',
    piholeEnabled: 'Habilitado',
    piholeDisabled: 'Deshabilitado',
    piholeTotalQueries: 'Consultas Totales',
    piholeBlockedQueries: 'Consultas Bloqueadas',
    piholePercentBlocked: '% Bloqueado',
    piholeTopBlocked: 'Top Bloqueados',
    piholeTopDomains: 'Top Dominios',
    piholeClients: 'Top Clientes',
    piholeDomains: 'Dominios',
    piholeGravity: 'Dominios Gravity',
    piholeToggle: 'Alternar Bloqueo',
    piholeQueries: 'Estadísticas de Consultas',
    piholeCached: 'En caché',
    piholeForwarded: 'Reenviadas',
    piholeUniqueDomains: 'Dominios Únicos',
    piholeBlockingWarningTitle: 'Bloqueo de anuncios',
    piholeBlockingWarningEnable: '¿Quieres volver a habilitar el bloqueo de anuncios? Todas las consultas DNS volverán a filtrarse a través de las listas de bloqueo.',
    piholeBlockingWarningDisable: '¿Quieres deshabilitar el bloqueo de anuncios? Se permitirán temporalmente todos los anuncios y rastreadores. Las consultas DNS ya no se filtrarán.',
    piholeBlockingDesc: 'El bloqueo de DNS está activo. Anuncios, rastreadores y dominios maliciosos se filtran automáticamente.',
    piholeDisableDesc: 'El bloqueo de DNS está deshabilitado. Todo el tráfico pasa sin filtrarse.',
    piholeGravityUpdated: 'Última actualización de Gravity',
    piholeOverview: 'Resumen',
    piholeQueryActivity: 'Actividad de Consultas',

    beszelSystems: 'Sistemas',
    beszelUp: 'En línea',
    beszelDown: 'Fuera de línea',
    beszelCpu: 'CPU',
    beszelMemory: 'Memoria',
    beszelDisk: 'Disco',
    beszelNetwork: 'Red',
    beszelUptime: 'Tpo. activ.',
    beszelNoSystems: 'No se encontraron sistemas',
    beszelSystemDetail: 'Detalles del Sistema',
    beszelOs: 'Sistema Operativo',
    beszelKernel: 'Kernel',
    beszelHostname: 'Nombre de host',
    beszelCpuModel: 'Modelo de CPU',
    beszelTotalMemory: 'Memoria Total',
    beszelUsedMemory: 'Memoria Usada',
    beszelTotalDisk: 'Disco Total',
    beszelUsedDisk: 'Disco Usado',
    beszelNetworkSent: 'Enviado',
    beszelNetworkReceived: 'Recibido',
    beszelRefreshRate: 'Se actualiza cada 15s',
    beszelCores: 'Núcleos',
    beszelSystemInfo: 'Información del Sistema',
    beszelResources: 'Recursos',
    beszelNetworkTraffic: 'Tráfico de Red',

    giteaRepos: 'Repositorios',
    giteaOrgs: 'Organizaciones',
    giteaStars: 'Estrellas',
    giteaForks: 'Forks (Bifurcaciones)',
    giteaIssues: 'Problemas (Issues)',
    giteaPrivate: 'Privado',
    giteaPublic: 'Público',
    giteaNoRepos: 'No se encontraron repositorios',
    giteaLanguage: 'Lenguaje',
    gitea2FAHint: 'Autenticación de dos factores',
    gitea2FAHintMessage: 'Si tienes habilitada la autenticación de dos factores (2FA) en Gitea, deberás generar una contraseña de aplicación. Ve a Ajustes → Aplicaciones en tu Gitea para crear una y usa esa contraseña aquí.',
    giteaFiles: 'Archivos',
    giteaCommits: 'Commits',
    giteaBranches: 'Ramas',
    giteaNoFiles: 'Sin archivos',
    giteaNoCommits: 'Sin commits',
    giteaNoIssues: 'Sin problemas',
    giteaOpenIssues: 'Abiertos',
    giteaClosedIssues: 'Cerrados',
    giteaDefaultBranch: 'Rama por Defecto',
    giteaSize: 'Tamaño',
    giteaLastUpdate: 'Última actualización',
    giteaReadme: 'LÉAME (README)',
    giteaOk: 'Entendido',
    giteaContributions: 'Contribuciones',
    giteaFileContent: 'Contenido del Archivo',
    giteaLessActive: 'Menos',
    giteaMoreActive: 'Más',
    giteaMyForks: 'Forks (Mis)',
    giteaPreview: 'Vista previa',
    giteaCode: 'Código',

    beszelContainers: 'Contenedores',
    beszelNoContainers: 'Sin contenedores',

    piholeQueriesOverTime: 'Consultas a lo largo del tiempo',

    settingsPreferences: 'Preferencias',
    settingsLanguage: 'Idioma',
    settingsTheme: 'Tema',
    settingsThemeLight: 'Claro',
    settingsThemeDark: 'Oscuro',
    settingsItalian: 'Italiano',
    settingsEnglish: 'English',
    settingsFrench: 'Français',
    settingsSpanish: 'Español',
    settingsGerman: 'Deutsch',
    settingsServices: 'Servicios Configurados',
    settingsDisconnect: 'Desconectar',
    settingsDisconnectConfirm: 'Desconectar',
    settingsDisconnectMessage: '¿Estás seguro de que quieres desconectarte de este servicio?',
    settingsAbout: 'Acerca de',
    settingsVersion: 'Versión',
    settingsConnected: 'Conectado',
    settingsNotConnected: 'No conectado',
};

const de: Translations = {
    loading: 'Wird geladen...',
    error: 'Fehler',
    cancel: 'Abbrechen',
    save: 'Speichern',
    confirm: 'Bestätigen',
    delete: 'Löschen',
    back: 'Zurück',
    close: 'Schließen',
    copy: 'Kopieren',
    yes: 'Ja',
    no: 'Nein',
    noData: 'Keine Daten',
    retry: 'Wiederholen',

    tabHome: 'Start',
    tabSettings: 'Einstellungen',

    launcherTitle: 'HomeLab',
    launcherSubtitle: 'Ihr Kontrollzentrum',
    launcherConnected: 'Verbunden',
    launcherNotConfigured: 'Nicht konfiguriert',
    launcherTapToConnect: 'Zum Verbinden tippen',
    launcherServices: 'Dienste',

    statusUnreachable: 'Nicht erreichbar',
    statusVerifying: 'Überprüfung...',
    actionReconnect: 'Neu verbinden',

    greetingMorning: 'Guten Morgen',
    greetingAfternoon: 'Guten Tag',
    greetingEvening: 'Guten Abend',
    summaryTitle: 'Übersicht',
    summaryQueryTotal: 'Gesamtanfragen',
    summarySystemsOnline: 'Systeme Online',

    servicePortainer: 'Portainer',
    servicePihole: 'Pi-hole',
    serviceBeszel: 'Beszel',
    serviceGitea: 'Gitea',
    servicePortainerDesc: 'Docker-Container-Management',
    servicePiholeDesc: 'Netzwerkweites Werbeblocken',
    serviceBeszelDesc: 'Server-Überwachung',
    serviceGiteaDesc: 'Selbstgehostetes Git',

    loginTitle: 'Verbinden',
    loginSubtitle: 'Dienst-Anmeldedaten eingeben',
    loginUrl: 'Server-URL',
    loginUrlPlaceholder: 'https://dienst.beispiel.com',
    loginUsername: 'Benutzername',
    loginEmail: 'E-Mail',
    loginPassword: 'Passwort',
    loginConnect: 'Verbinden',
    loginConnecting: 'Verbinde...',
    loginErrorUrl: 'Bitte Server-URL eingeben',
    loginErrorCredentials: 'Bitte Anmeldedaten eingeben',
    loginErrorFailed: 'Verbindung fehlgeschlagen',
    loginHintPihole: 'Verwenden Sie das in Pi-hole konfigurierte Passwort (Einstellungen → API / Web Interface → API-Passwort)',
    loginHintGitea2FA: 'Wenn Sie Zwei-Faktor-Authentifizierung (2FA) aktiviert haben, generieren Sie ein App-Passwort in den Gitea-Einstellungen unter Anwendungen.',

    portainerDashboard: 'Portainer',
    portainerEndpoints: 'Endpunkte',
    portainerActive: 'Aktiv',
    portainerContainers: 'Container',
    portainerResources: 'Ressourcen',
    portainerTotal: 'Gesamt',
    portainerRunning: 'Läuft',
    portainerStopped: 'Gestoppt',
    portainerImages: 'Images',
    portainerVolumes: 'Volumes',
    portainerCpus: 'CPUs',
    portainerMemory: 'Speicher',
    portainerViewAll: 'Alle Container ansehen',
    portainerSelectEndpoint: 'Endpunkt auswählen',
    portainerServerInfo: 'Server Info',
    portainerOnline: 'Online',
    portainerOffline: 'Offline',
    portainerStacks: 'Stacks',
    portainerHealthy: 'Gesund',
    portainerUnhealthy: 'Ungesund',

    containersSearch: 'Container suchen...',
    containersAll: 'Alle',
    containersRunning: 'Läuft',
    containersStopped: 'Gestoppt',
    containersEmpty: 'Keine Container gefunden',
    containersNoEndpoint: 'Wählen Sie zuerst einen Endpunkt',

    actionStart: 'Starten',
    actionStop: 'Stoppen',
    actionRestart: 'Neustarten',
    actionPause: 'Pausieren',
    actionResume: 'Fortsetzen',
    actionRemove: 'Entfernen',
    actionKill: 'Beenden',
    actionConfirm: 'Aktion bestätigen',
    actionConfirmMessage: 'Sind Sie sicher, dass Sie diese Aktion durchführen möchten?',
    actionRemoveConfirm: 'Container entfernen',
    actionRemoveMessage: 'Diese Aktion ist unwiderruflich. Fortfahren?',

    detailInfo: 'Info',
    detailStats: 'Stats',
    detailLogs: 'Logs',
    detailEnv: 'Env',
    detailCompose: 'Compose',
    detailContainer: 'Container',
    detailCreated: 'Erstellt am',
    detailHostname: 'Hostname',
    detailWorkDir: 'Arbeitsverz.',
    detailCommand: 'Befehl',
    detailNetwork: 'Netzwerk',
    detailMode: 'Modus',
    detailMounts: 'Mounts',
    detailRestartPolicy: 'Neustart-Richtlinie',
    detailPolicy: 'Richtlinie',
    detailMaxRetries: 'Max. Versuche',
    detailUptime: 'Laufzeit',
    detailNotRunning: 'Container läuft nicht',
    detailNoLogs: 'Keine Logs verfügbar',
    detailEnvVars: 'Umgebungsvariablen',
    detailCpu: 'CPU',
    detailMemory: 'Speicher',
    detailNetworkIO: 'Netzwerk I/O',
    detailUsed: 'verwendet',
    detailContainerLogs: 'Container Logs',
    detailNotFound: 'Container nicht gefunden',
    detailComposeFile: 'Docker Compose Datei',
    detailComposeNotAvailable: 'Docker Compose für diesen Container nicht verfügbar',
    detailComposeSave: 'Änderungen speichern',
    detailComposeSaved: 'Compose erfolgreich gespeichert',
    detailComposeSaveError: 'Fehler beim Speichern von Compose',
    detailComposeLoading: 'Lade Compose...',

    piholeBlocking: 'Werbeblocker',
    piholeEnabled: 'Aktiviert',
    piholeDisabled: 'Deaktiviert',
    piholeTotalQueries: 'Gesamtanfragen',
    piholeBlockedQueries: 'Blockierte Anfragen',
    piholePercentBlocked: '% Blockiert',
    piholeTopBlocked: 'Top Blockiert',
    piholeTopDomains: 'Top Domains',
    piholeClients: 'Top Clients',
    piholeDomains: 'Domains',
    piholeGravity: 'Gravity Domains',
    piholeToggle: 'Blocker umschalten',
    piholeQueries: 'Anfrage-Statistiken',
    piholeCached: 'Zwischengespeichert',
    piholeForwarded: 'Weitergeleitet',
    piholeUniqueDomains: 'Einzigartige Domains',
    piholeBlockingWarningTitle: 'Werbeblocker',
    piholeBlockingWarningEnable: 'Möchten Sie den Werbeblocker wieder aktivieren? Alle DNS-Anfragen werden erneut gefiltert.',
    piholeBlockingWarningDisable: 'Möchten Sie den Werbeblocker deaktivieren? Alle Anzeigen und Tracker werden vorübergehend zugelassen.',
    piholeBlockingDesc: 'DNS-Blocker ist aktiv. Werbung, Tracker und schädliche Domains werden blockiert.',
    piholeDisableDesc: 'DNS-Blocker ist deaktiviert. Gesamter Datenverkehr wird unreguliert durchgelassen.',
    piholeGravityUpdated: 'Letztes Gravity Update',
    piholeOverview: 'Übersicht',
    piholeQueryActivity: 'Anfrage-Aktivität',

    beszelSystems: 'Systeme',
    beszelUp: 'Online',
    beszelDown: 'Offline',
    beszelCpu: 'CPU',
    beszelMemory: 'Speicher',
    beszelDisk: 'Festplatte',
    beszelNetwork: 'Netzwerk',
    beszelUptime: 'Laufzeit',
    beszelNoSystems: 'Keine Systeme gefunden',
    beszelSystemDetail: 'Systemdetails',
    beszelOs: 'Betriebssystem',
    beszelKernel: 'Kernel',
    beszelHostname: 'Hostname',
    beszelCpuModel: 'CPU Modell',
    beszelTotalMemory: 'Gesamtspeicher',
    beszelUsedMemory: 'Verwendeter Speicher',
    beszelTotalDisk: 'Gesamter Speicherplatz',
    beszelUsedDisk: 'Verwendeter Speicherplatz',
    beszelNetworkSent: 'Gesendet',
    beszelNetworkReceived: 'Empfangen',
    beszelRefreshRate: 'Aktualisiert alle 15s',
    beszelCores: 'Kerne',
    beszelSystemInfo: 'Systeminformationen',
    beszelResources: 'Ressourcen',
    beszelNetworkTraffic: 'Netzwerktraffic',

    giteaRepos: 'Repositories',
    giteaOrgs: 'Organisationen',
    giteaStars: 'Sterne',
    giteaForks: 'Forks',
    giteaIssues: 'Probleme (Issues)',
    giteaPrivate: 'Privat',
    giteaPublic: 'Öffentlich',
    giteaNoRepos: 'Keine Repositories gefunden',
    giteaLanguage: 'Sprache',
    gitea2FAHint: 'Zwei-Faktor-Authentifizierung',
    gitea2FAHintMessage: 'Wenn 2FA aktiviert ist, müssen Sie in den Gitea-Einstellungen (Anwendungen) ein App-Passwort erstellen und es hier verwenden.',
    giteaFiles: 'Dateien',
    giteaCommits: 'Commits',
    giteaBranches: 'Branches',
    giteaNoFiles: 'Keine Dateien',
    giteaNoCommits: 'Keine Commits',
    giteaNoIssues: 'Keine Issues',
    giteaOpenIssues: 'Offen',
    giteaClosedIssues: 'Geschlossen',
    giteaDefaultBranch: 'Standard-Branch',
    giteaSize: 'Größe',
    giteaLastUpdate: 'Zuletzt aktualisiert',
    giteaReadme: 'LIESMICH (README)',
    giteaOk: 'Verstanden',
    giteaContributions: 'Beiträge',
    giteaFileContent: 'Dateiinhalte',
    giteaLessActive: 'Weniger',
    giteaMoreActive: 'Mehr',
    giteaMyForks: 'Forks (Meine)',
    giteaPreview: 'Vorschau',
    giteaCode: 'Code',

    beszelContainers: 'Container',
    beszelNoContainers: 'Keine Container',

    piholeQueriesOverTime: 'Anfragen im Zeitverlauf',

    settingsPreferences: 'Präferenzen',
    settingsLanguage: 'Sprache',
    settingsTheme: 'Design',
    settingsThemeLight: 'Hell',
    settingsThemeDark: 'Dunkel',
    settingsItalian: 'Italiano',
    settingsEnglish: 'English',
    settingsFrench: 'Français',
    settingsSpanish: 'Español',
    settingsGerman: 'Deutsch',
    settingsServices: 'Konfigurierte Dienste',
    settingsDisconnect: 'Trennen',
    settingsDisconnectConfirm: 'Trennen',
    settingsDisconnectMessage: 'Möchten Sie diesen Dienst wirklich trennen?',
    settingsAbout: 'Über',
    settingsVersion: 'Version',
    settingsConnected: 'Verbunden',
    settingsNotConnected: 'Nicht verbunden',
};

export const translations: Record<Language, Translations> = { it, en, fr, es, de };

