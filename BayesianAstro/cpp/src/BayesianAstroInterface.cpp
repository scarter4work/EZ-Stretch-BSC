/**
 * BayesianAstro Interface Implementation
 *
 * Process interface with embedded React UI via QWebEngineView.
 */

#include "BayesianAstroInterface.h"
#include "BayesianAstroProcess.h"

#include <pcl/Console.h>
#include <pcl/ErrorHandler.h>

#include <QVBoxLayout>
#include <QUrl>
#include <QDir>
#include <QCoreApplication>

namespace pcl
{

BayesianAstroInterface* TheBayesianAstroInterface = nullptr;

// ============================================================================
// BayesianAstroBridge Implementation
// ============================================================================

BayesianAstroBridge::BayesianAstroBridge(QObject* parent)
    : QObject(parent)
{
}

int BayesianAstroBridge::fusionStrategy() const
{
    return m_instance ? m_instance->FusionStrategy() : 1;
}

void BayesianAstroBridge::setFusionStrategy(int value)
{
    if (m_instance && m_instance->FusionStrategy() != value)
    {
        m_instance->SetFusionStrategy(value);
        emit fusionStrategyChanged();
    }
}

float BayesianAstroBridge::outlierSigma() const
{
    return m_instance ? m_instance->OutlierSigma() : 3.0f;
}

void BayesianAstroBridge::setOutlierSigma(float value)
{
    if (m_instance)
    {
        m_instance->SetOutlierSigma(value);
        emit outlierSigmaChanged();
    }
}

float BayesianAstroBridge::confidenceThreshold() const
{
    return m_instance ? m_instance->ConfidenceThreshold() : 0.1f;
}

void BayesianAstroBridge::setConfidenceThreshold(float value)
{
    if (m_instance)
    {
        m_instance->SetConfidenceThreshold(value);
        emit confidenceThresholdChanged();
    }
}

bool BayesianAstroBridge::useGPU() const
{
    return m_instance ? m_instance->UseGPU() : true;
}

void BayesianAstroBridge::setUseGPU(bool value)
{
    if (m_instance)
    {
        m_instance->SetUseGPU(value);
        emit useGPUChanged();
    }
}

bool BayesianAstroBridge::generateConfidenceMap() const
{
    return m_instance ? m_instance->GenerateConfidenceMap() : true;
}

void BayesianAstroBridge::setGenerateConfidenceMap(bool value)
{
    if (m_instance)
    {
        m_instance->SetGenerateConfidenceMap(value);
        emit generateConfidenceMapChanged();
    }
}

void BayesianAstroBridge::addFiles(const QStringList& paths)
{
    if (!m_instance) return;

    for (const QString& path : paths)
    {
        m_instance->AddInputFile(String(path.toUtf8().constData()));
    }
    emit filesChanged();
}

void BayesianAstroBridge::removeFile(int index)
{
    // TODO: Implement removal by index
    emit filesChanged();
}

void BayesianAstroBridge::clearFiles()
{
    if (m_instance)
    {
        m_instance->ClearInputFiles();
        emit filesChanged();
    }
}

QStringList BayesianAstroBridge::getFiles() const
{
    QStringList result;
    if (m_instance)
    {
        for (const String& s : m_instance->InputFiles())
            result.append(QString::fromUtf8(s.ToUTF8().c_str()));
    }
    return result;
}

void BayesianAstroBridge::execute()
{
    if (!m_instance) return;

    try
    {
        bool success = m_instance->ExecuteGlobal();
        emit executionComplete(success, success ? "Processing complete" : "Processing failed");
    }
    catch (const Exception& e)
    {
        emit executionComplete(false, QString::fromUtf8(e.Message().ToUTF8().c_str()));
    }
    catch (...)
    {
        emit executionComplete(false, "Unknown error occurred");
    }
}

void BayesianAstroBridge::setOutputDirectory(const QString& path)
{
    if (m_instance)
        m_instance->SetOutputDirectory(String(path.toUtf8().constData()));
}

void BayesianAstroBridge::setOutputPrefix(const QString& prefix)
{
    if (m_instance)
        m_instance->SetOutputPrefix(String(prefix.toUtf8().constData()));
}

void BayesianAstroBridge::reportProgress(int percent, const QString& status)
{
    emit progressUpdated(percent, status);
}

// ============================================================================
// BayesianAstroInterface Implementation
// ============================================================================

BayesianAstroInterface::BayesianAstroInterface()
    : m_instance(TheBayesianAstroProcess)
{
    TheBayesianAstroInterface = this;
}

BayesianAstroInterface::~BayesianAstroInterface()
{
    if (m_webView)
    {
        delete m_webView;
        m_webView = nullptr;
    }
    if (m_webChannel)
    {
        delete m_webChannel;
        m_webChannel = nullptr;
    }
    if (m_bridge)
    {
        delete m_bridge;
        m_bridge = nullptr;
    }

    TheBayesianAstroInterface = nullptr;
}

IsoString BayesianAstroInterface::Id() const
{
    return "BayesianAstro";
}

MetaProcess* BayesianAstroInterface::Process() const
{
    return TheBayesianAstroProcess;
}

String BayesianAstroInterface::IconImageSVGFile() const
{
    return String();  // TODO: Add icon
}

InterfaceFeatures BayesianAstroInterface::Features() const
{
    return InterfaceFeature::Default;
}

void BayesianAstroInterface::ApplyInstance() const
{
    m_instance.ExecuteGlobal();
}

void BayesianAstroInterface::ResetInstance()
{
    BayesianAstroInstance defaultInstance(TheBayesianAstroProcess);
    ImportProcess(defaultInstance);
}

bool BayesianAstroInterface::Launch(const MetaProcess&, const ProcessImplementation* instance, bool& dynamic, unsigned& flags)
{
    if (instance != nullptr)
        ImportProcess(*instance);

    dynamic = false;
    return true;
}

ProcessImplementation* BayesianAstroInterface::NewProcess() const
{
    return new BayesianAstroInstance(m_instance);
}

bool BayesianAstroInterface::ValidateProcess(const ProcessImplementation& p, String& whyNot) const
{
    if (dynamic_cast<const BayesianAstroInstance*>(&p) == nullptr)
    {
        whyNot = "Not a BayesianAstro instance";
        return false;
    }
    return true;
}

bool BayesianAstroInterface::RequiresInstanceValidation() const
{
    return true;
}

bool BayesianAstroInterface::ImportProcess(const ProcessImplementation& p)
{
    m_instance.Assign(p);
    SyncInstanceToUI();
    return true;
}

QWidget* BayesianAstroInterface::CreateWidget()
{
    QWidget* container = new QWidget();
    QVBoxLayout* layout = new QVBoxLayout(container);
    layout->setContentsMargins(0, 0, 0, 0);

    InitializeWebView();

    layout->addWidget(m_webView);
    container->setMinimumSize(800, 600);

    return container;
}

void BayesianAstroInterface::InitializeWebView()
{
    m_webView = new QWebEngineView();
    m_webChannel = new QWebChannel(m_webView->page());
    m_bridge = new BayesianAstroBridge();

    m_bridge->SetInstance(&m_instance);

    // Register bridge object for JavaScript access
    m_webChannel->registerObject(QStringLiteral("bayesianAstro"), m_bridge);
    m_webView->page()->setWebChannel(m_webChannel);

    // Load React app from bundled assets
    QString uiPath = QCoreApplication::applicationDirPath() + "/share/BayesianAstro/ui/index.html";

    if (QDir().exists(uiPath))
    {
        m_webView->load(QUrl::fromLocalFile(uiPath));
    }
    else
    {
        // Development fallback - load from dev server
        m_webView->load(QUrl("http://localhost:5173"));
    }
}

void BayesianAstroInterface::SyncInstanceToUI()
{
    if (m_bridge)
    {
        emit m_bridge->fusionStrategyChanged();
        emit m_bridge->outlierSigmaChanged();
        emit m_bridge->confidenceThresholdChanged();
        emit m_bridge->useGPUChanged();
        emit m_bridge->generateConfidenceMapChanged();
        emit m_bridge->filesChanged();
    }
}

void BayesianAstroInterface::SyncUIToInstance()
{
    // UI changes are synced immediately via property setters
}

} // namespace pcl
