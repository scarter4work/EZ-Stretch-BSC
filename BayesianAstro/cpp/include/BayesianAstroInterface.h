/**
 * BayesianAstro Interface
 *
 * Process interface with embedded React UI via QWebEngineView.
 */

#ifndef __BayesianAstroInterface_h
#define __BayesianAstroInterface_h

#include <pcl/ProcessInterface.h>
#include <pcl/Sizer.h>

#include <QtWebEngineWidgets/QWebEngineView>
#include <QtWebChannel/QWebChannel>
#include <QWidget>

#include "BayesianAstroInstance.h"

namespace pcl
{

// Bridge object exposed to JavaScript via QWebChannel
class BayesianAstroBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int fusionStrategy READ fusionStrategy WRITE setFusionStrategy NOTIFY fusionStrategyChanged)
    Q_PROPERTY(float outlierSigma READ outlierSigma WRITE setOutlierSigma NOTIFY outlierSigmaChanged)
    Q_PROPERTY(float confidenceThreshold READ confidenceThreshold WRITE setConfidenceThreshold NOTIFY confidenceThresholdChanged)
    Q_PROPERTY(bool useGPU READ useGPU WRITE setUseGPU NOTIFY useGPUChanged)
    Q_PROPERTY(bool generateConfidenceMap READ generateConfidenceMap WRITE setGenerateConfidenceMap NOTIFY generateConfidenceMapChanged)

public:
    explicit BayesianAstroBridge(QObject* parent = nullptr);

    // Property accessors
    int fusionStrategy() const;
    void setFusionStrategy(int value);

    float outlierSigma() const;
    void setOutlierSigma(float value);

    float confidenceThreshold() const;
    void setConfidenceThreshold(float value);

    bool useGPU() const;
    void setUseGPU(bool value);

    bool generateConfidenceMap() const;
    void setGenerateConfidenceMap(bool value);

    // Link to instance
    void SetInstance(BayesianAstroInstance* instance) { m_instance = instance; }

public slots:
    // Called from JavaScript
    void addFiles(const QStringList& paths);
    void removeFile(int index);
    void clearFiles();
    QStringList getFiles() const;
    void execute();
    void setOutputDirectory(const QString& path);
    void setOutputPrefix(const QString& prefix);

    // Progress reporting
    void reportProgress(int percent, const QString& status);

signals:
    void fusionStrategyChanged();
    void outlierSigmaChanged();
    void confidenceThresholdChanged();
    void useGPUChanged();
    void generateConfidenceMapChanged();
    void filesChanged();
    void progressUpdated(int percent, const QString& status);
    void executionComplete(bool success, const QString& message);

private:
    BayesianAstroInstance* m_instance = nullptr;
};

class BayesianAstroInterface : public ProcessInterface
{
public:
    BayesianAstroInterface();
    virtual ~BayesianAstroInterface();

    IsoString Id() const override;
    MetaProcess* Process() const override;
    String IconImageSVGFile() const override;
    InterfaceFeatures Features() const override;
    void ApplyInstance() const override;
    void ResetInstance() override;
    bool Launch(const MetaProcess&, const ProcessImplementation*, bool& dynamic, unsigned& flags) override;
    ProcessImplementation* NewProcess() const override;
    bool ValidateProcess(const ProcessImplementation&, String& whyNot) const override;
    bool RequiresInstanceValidation() const override;
    bool ImportProcess(const ProcessImplementation&) override;

    // Qt widget for embedding in PixInsight dialog
    QWidget* CreateWidget();

private:
    BayesianAstroInstance m_instance;

    // Qt components
    QWebEngineView* m_webView = nullptr;
    QWebChannel* m_webChannel = nullptr;
    BayesianAstroBridge* m_bridge = nullptr;

    void InitializeWebView();
    void SyncInstanceToUI();
    void SyncUIToInstance();
};

extern BayesianAstroInterface* TheBayesianAstroInterface;

} // namespace pcl

#endif // __BayesianAstroInterface_h
