/// Localization strings for ElectroNorm Pro
/// Supporting Spanish (es), English (en), and Portuguese (pt)
class AppStrings {
  // Navigation & Common
  final String appTitle;
  final String appSubtitle;
  final String cancel;
  final String save;
  final String delete;
  final String close;
  final String enterApp;
  final String newCalculation;
  final String savedProjects;
  final String cleanCalculation;
  final String settings;
  final String proActive;
  final String proBadge;

  // Settings & Technician Profile
  final String settingsTitle;
  final String languageSelectorTitle;
  final String languageSelectorSubtitle;
  final String languageSpanish;
  final String languageEnglish;
  final String languagePortuguese;
  final String technicianProfileHeader;
  final String technicianProfileDesc;
  final String technicianNameLabel;
  final String companyNameLabel;
  final String licenseNumberLabel;
  final String emailLabel;
  final String phoneLabel;
  final String agencyNameLabel;
  final String addressLabel;
  final String saveSettingsBtn;
  final String settingsSavedSuccess;
  final String technicalStandardsHeader;
  final String technicalStandardsDesc;
  final String appInfoTitle;
  final String appVersion;
  final String privacyPolicyBtn;
  final String termsBtn;

  // Pro & Subscription Banner
  final String proActiveTitle;
  final String proActiveSubtitle;
  final String freePlanTitle;
  final String freePlanSubtitle;
  final String upgradeBtn;
  final String trialActiveTitle;

  // Calculator Screen
  final String racewaySectionTitle;
  final String conductorsSectionTitle;
  final String addConductorBtn;
  final String complianceSummaryTitle;
  final String conduitFillTab;
  final String voltageDropTab;
  final String deratingTab;
  final String exportPdfBtn;
  final String saveProjectBtn;
  final String compliantBadge;
  final String violationBadge;

  // Saved Projects Screen
  final String savedProjectsTitle;
  final String noSavedProjectsTitle;
  final String noSavedProjectsDesc;
  final String loadProjectBtn;
  final String deleteProjectConfirm;

  // PDF & Reports
  final String pdfReportTitle;
  final String pdfGeneratedDate;
  final String pdfInspectorHeader;
  final String pdfCalculationsHeader;

  const AppStrings({
    required this.appTitle,
    required this.appSubtitle,
    required this.cancel,
    required this.save,
    required this.delete,
    required this.close,
    required this.enterApp,
    required this.newCalculation,
    required this.savedProjects,
    required this.cleanCalculation,
    required this.settings,
    required this.proActive,
    required this.proBadge,
    required this.settingsTitle,
    required this.languageSelectorTitle,
    required this.languageSelectorSubtitle,
    required this.languageSpanish,
    required this.languageEnglish,
    required this.languagePortuguese,
    required this.technicianProfileHeader,
    required this.technicianProfileDesc,
    required this.technicianNameLabel,
    required this.companyNameLabel,
    required this.licenseNumberLabel,
    required this.emailLabel,
    required this.phoneLabel,
    required this.agencyNameLabel,
    required this.addressLabel,
    required this.saveSettingsBtn,
    required this.settingsSavedSuccess,
    required this.technicalStandardsHeader,
    required this.technicalStandardsDesc,
    required this.appInfoTitle,
    required this.appVersion,
    required this.privacyPolicyBtn,
    required this.termsBtn,
    required this.proActiveTitle,
    required this.proActiveSubtitle,
    required this.freePlanTitle,
    required this.freePlanSubtitle,
    required this.upgradeBtn,
    required this.trialActiveTitle,
    required this.racewaySectionTitle,
    required this.conductorsSectionTitle,
    required this.addConductorBtn,
    required this.complianceSummaryTitle,
    required this.conduitFillTab,
    required this.voltageDropTab,
    required this.deratingTab,
    required this.exportPdfBtn,
    required this.saveProjectBtn,
    required this.compliantBadge,
    required this.violationBadge,
    required this.savedProjectsTitle,
    required this.noSavedProjectsTitle,
    required this.noSavedProjectsDesc,
    required this.loadProjectBtn,
    required this.deleteProjectConfirm,
    required this.pdfReportTitle,
    required this.pdfGeneratedDate,
    required this.pdfInspectorHeader,
    required this.pdfCalculationsHeader,
  });

  // ==========================================
  // SPANISH (Default)
  // ==========================================
  static const es = AppStrings(
    appTitle: 'ELECTRONORM',
    appSubtitle: 'Cálculos Eléctricos & Reportes NEC',
    cancel: 'Cancelar',
    save: 'Guardar',
    delete: 'Eliminar',
    close: 'Cerrar',
    enterApp: 'Entrar',
    newCalculation: '+ Nuevo Cálculo',
    savedProjects: 'Proyectos Guardados',
    cleanCalculation: 'Limpiar / Nuevo',
    settings: 'Ajustes',
    proActive: 'PRO ACTIVO',
    proBadge: 'PRO',
    settingsTitle: 'Ajustes & Perfil Técnico',
    languageSelectorTitle: 'IDIOMA DE LA APLICACIÓN',
    languageSelectorSubtitle: 'Selecciona tu idioma preferido para la interfaz y reportes',
    languageSpanish: 'Español',
    languageEnglish: 'English',
    languagePortuguese: 'Português',
    technicianProfileHeader: 'PERFIL PROFESIONAL DEL TÉCNICO',
    technicianProfileDesc: 'Estos datos se incluirán automáticamente en la cabecera de tus memorias de cálculo y reportes técnicos en PDF.',
    technicianNameLabel: 'Ingeniero / Técnico Responsable',
    companyNameLabel: 'Empresa / Razón Social',
    licenseNumberLabel: 'Matrícula / Licencia Profesional',
    emailLabel: 'Correo Electrónico',
    phoneLabel: 'Teléfono de Contacto',
    agencyNameLabel: 'Organismo de Inspección / AHJ',
    addressLabel: 'Dirección o Ciudad de Operación',
    saveSettingsBtn: 'Guardar Ajustes y Perfil',
    settingsSavedSuccess: 'Ajustes guardados correctamente',
    technicalStandardsHeader: 'NORMAS TÉCNICAS APLICADAS',
    technicalStandardsDesc: 'Cálculos ejecutados conforme a NEC (NFPA 70), NOM-001-SEDE, RETIE y NBR 5410.',
    appInfoTitle: 'INFORMACIÓN DE LA APLICACIÓN',
    appVersion: 'ElectroNorm Pro v1.0.0 (SimpleApps PG)',
    privacyPolicyBtn: 'Política de Privacidad',
    termsBtn: 'Términos de Servicio',
    proActiveTitle: 'Suscripción Pro Activa',
    proActiveSubtitle: 'Acceso ilimitado a cálculos, canalizaciones y reportes PDF.',
    freePlanTitle: 'Plan Estándar (Prueba)',
    freePlanSubtitle: 'Desbloquea exportación PDF ilimitada y todos los tipos de tubería.',
    upgradeBtn: 'Mejorar a Pro',
    trialActiveTitle: 'Prueba Pro Activa',
    racewaySectionTitle: 'Tipo de Canalización y Diámetro',
    conductorsSectionTitle: 'Conductores en Tubería',
    addConductorBtn: '+ Agregar Conductor',
    complianceSummaryTitle: 'Resumen de Cumplimiento Normativo',
    conduitFillTab: 'Llenado de Tubería',
    voltageDropTab: 'Caída de Tensión',
    deratingTab: 'Factor de Corrección',
    exportPdfBtn: 'Exportar Memoria PDF',
    saveProjectBtn: 'Guardar Proyecto',
    compliantBadge: 'CUMPLE',
    violationBadge: 'NO CUMPLE',
    savedProjectsTitle: 'Proyectos Guardados',
    noSavedProjectsTitle: 'Sin proyectos guardados',
    noSavedProjectsDesc: 'Realiza un cálculo y pulsa en "Guardar Proyecto" para archivarlo aquí.',
    loadProjectBtn: 'Cargar Cálculo',
    deleteProjectConfirm: '¿Deseas eliminar este cálculo guardado?',
    pdfReportTitle: 'MEMORIA DE CÁLCULO ELÉCTRICO',
    pdfGeneratedDate: 'Fecha de Emisión',
    pdfInspectorHeader: 'DATOS DEL TÉCNICO Y AUTORIDAD COMPETENTE',
    pdfCalculationsHeader: 'ANÁLISIS DE OCUPACIÓN Y PARÁMETROS TÉCNICOS',
  );

  // ==========================================
  // ENGLISH
  // ==========================================
  static const en = AppStrings(
    appTitle: 'ELECTRONORM',
    appSubtitle: 'Electrical Calculations & NEC Reports',
    cancel: 'Cancel',
    save: 'Save',
    delete: 'Delete',
    close: 'Close',
    enterApp: 'Enter',
    newCalculation: '+ New Calculation',
    savedProjects: 'Saved Projects',
    cleanCalculation: 'Clear / New',
    settings: 'Settings',
    proActive: 'PRO ACTIVE',
    proBadge: 'PRO',
    settingsTitle: 'Settings & Technician Profile',
    languageSelectorTitle: 'APPLICATION LANGUAGE',
    languageSelectorSubtitle: 'Select your preferred language for the interface and reports',
    languageSpanish: 'Spanish',
    languageEnglish: 'English',
    languagePortuguese: 'Portuguese',
    technicianProfileHeader: 'TECHNICIAN & PROFESSIONAL PROFILE',
    technicianProfileDesc: 'This information will be automatically embedded in your technical reports and PDF calculation sheets.',
    technicianNameLabel: 'Engineer / Licensed Electrician',
    companyNameLabel: 'Company / Business Name',
    licenseNumberLabel: 'Professional License / Certification #',
    emailLabel: 'Contact Email',
    phoneLabel: 'Contact Phone',
    agencyNameLabel: 'Inspection Bureau / AHJ Authority',
    addressLabel: 'Business Address or City',
    saveSettingsBtn: 'Save Settings & Profile',
    settingsSavedSuccess: 'Settings saved successfully',
    technicalStandardsHeader: 'APPLICABLE TECHNICAL CODES',
    technicalStandardsDesc: 'Calculations performed pursuant to NEC (NFPA 70), NOM-001, RETIE, and NBR 5410.',
    appInfoTitle: 'APPLICATION INFORMATION',
    appVersion: 'ElectroNorm Pro v1.0.0 (SimpleApps PG)',
    privacyPolicyBtn: 'Privacy Policy',
    termsBtn: 'Terms of Service',
    proActiveTitle: 'Pro Subscription Active',
    proActiveSubtitle: 'Unlimited calculations, conduit schedules, and formal PDF exports.',
    freePlanTitle: 'Standard Plan (Trial)',
    freePlanSubtitle: 'Unlock unlimited PDF generation and complete raceway catalog.',
    upgradeBtn: 'Upgrade to Pro',
    trialActiveTitle: 'Pro Trial Active',
    racewaySectionTitle: 'Raceway Type & Trade Size',
    conductorsSectionTitle: 'Conductors in Raceway',
    addConductorBtn: '+ Add Conductor',
    complianceSummaryTitle: 'Code Compliance Summary',
    conduitFillTab: 'Conduit Fill',
    voltageDropTab: 'Voltage Drop',
    deratingTab: 'Ampacity Derating',
    exportPdfBtn: 'Export PDF Report',
    saveProjectBtn: 'Save Project',
    compliantBadge: 'COMPLIANT',
    violationBadge: 'VIOLATION',
    savedProjectsTitle: 'Saved Projects',
    noSavedProjectsTitle: 'No saved projects',
    noSavedProjectsDesc: 'Run a calculation and tap "Save Project" to store it here.',
    loadProjectBtn: 'Load Calculation',
    deleteProjectConfirm: 'Do you want to delete this saved calculation?',
    pdfReportTitle: 'ELECTRICAL ENGINEERING CALCULATION REPORT',
    pdfGeneratedDate: 'Date of Issue',
    pdfInspectorHeader: 'ENGINEERING & INSPECTION AUTHORITY DATA',
    pdfCalculationsHeader: 'CONDUIT FILL & CODE PARAMETERS ANALYSIS',
  );

  // ==========================================
  // PORTUGUESE
  // ==========================================
  static const pt = AppStrings(
    appTitle: 'ELECTRONORM',
    appSubtitle: 'Cálculos Elétricos & Relatórios Técnicos',
    cancel: 'Cancelar',
    save: 'Salvar',
    delete: 'Excluir',
    close: 'Fechar',
    enterApp: 'Entrar',
    newCalculation: '+ Novo Cálculo',
    savedProjects: 'Projetos Salvos',
    cleanCalculation: 'Limpar / Novo',
    settings: 'Ajustes',
    proActive: 'PRO ATIVO',
    proBadge: 'PRO',
    settingsTitle: 'Ajustes & Perfil Técnico',
    languageSelectorTitle: 'IDIOMA DO APLICATIVO',
    languageSelectorSubtitle: 'Selecione seu idioma preferido para a interface e relatórios',
    languageSpanish: 'Espanhol',
    languageEnglish: 'Inglês',
    languagePortuguese: 'Português',
    technicianProfileHeader: 'PERFIL DO ENGENHEIRO / TÉCNICO',
    technicianProfileDesc: 'Esses dados serão inseridos automaticamente no cabeçalho das suas memórias de cálculo e relatórios em PDF.',
    technicianNameLabel: 'Engenheiro / Técnico Responsável',
    companyNameLabel: 'Empresa / Razão Social',
    licenseNumberLabel: 'Registro Profissional / CREA / CFT',
    emailLabel: 'E-mail de Contato',
    phoneLabel: 'Telefone de Contato',
    agencyNameLabel: 'Órgão de Fiscalização / Inspeção',
    addressLabel: 'Endereço Comercial ou Cidade',
    saveSettingsBtn: 'Salvar Ajustes e Perfil',
    settingsSavedSuccess: 'Ajustes salvos com sucesso',
    technicalStandardsHeader: 'NORMAS TÉCNICAS APLICADAS',
    technicalStandardsDesc: 'Cálculos executados conforme NBR 5410, NEC (NFPA 70), NOM e RETIE.',
    appInfoTitle: 'INFORMAÇÕES DO APLICATIVO',
    appVersion: 'ElectroNorm Pro v1.0.0 (SimpleApps PG)',
    privacyPolicyBtn: 'Política de Privacidade',
    termsBtn: 'Termos de Serviço',
    proActiveTitle: 'Assinatura Pro Ativa',
    proActiveSubtitle: 'Acesso ilimitado a cálculos, eletrodutos e relatórios técnicos em PDF.',
    freePlanTitle: 'Plano Padrão (Avaliação)',
    freePlanSubtitle: 'Desbloqueie exportação ilimitada de relatórios em PDF e catálogo completo.',
    upgradeBtn: 'Assinar Pro',
    trialActiveTitle: 'Avaliação Pro Ativa',
    racewaySectionTitle: 'Tipo de Eletroduto e Bitola',
    conductorsSectionTitle: 'Condutores no Eletroduto',
    addConductorBtn: '+ Adicionar Condutor',
    complianceSummaryTitle: 'Resumo de Conformidade Técnica',
    conduitFillTab: 'Taxa de Ocupação',
    voltageDropTab: 'Queda de Tensão',
    deratingTab: 'Fator de Correção',
    exportPdfBtn: 'Exportar Relatório PDF',
    saveProjectBtn: 'Salvar Projeto',
    compliantBadge: 'CONFORME',
    violationBadge: 'NÃO CONFORME',
    savedProjectsTitle: 'Projetos Salvos',
    noSavedProjectsTitle: 'Nenhum projeto salvo',
    noSavedProjectsDesc: 'Faça um cálculo e clique em "Salvar Projeto" para arquivá-lo aqui.',
    loadProjectBtn: 'Carregar Cálculo',
    deleteProjectConfirm: 'Deseja excluir este cálculo salvo?',
    pdfReportTitle: 'MEMÓRIA DE CÁLCULO ELÉTRICO',
    pdfGeneratedDate: 'Data de Emissão',
    pdfInspectorHeader: 'DADOS DO RESPONSÁVEL TÉCNICO E INSPEÇÃO',
    pdfCalculationsHeader: 'ANÁLISE DE OCUPAÇÃO E PARÂMETROS NORMATIVOS',
  );

  static AppStrings get(String localeCode) {
    if (localeCode.isEmpty) return es;
    final prefix = localeCode.toLowerCase().substring(0, localeCode.length >= 2 ? 2 : localeCode.length);
    switch (prefix) {
      case 'en':
        return en;
      case 'pt':
        return pt;
      case 'es':
      default:
        return es;
    }
  }
}
