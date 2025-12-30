/**
 * BayesianAstro Module Implementation
 */

#include "BayesianAstroModule.h"
#include "BayesianAstroProcess.h"
#include "BayesianAstroInterface.h"
#include "JuliaRuntime.h"

#include <pcl/Console.h>
#include <pcl/ErrorHandler.h>

namespace pcl
{

BayesianAstroModule* TheBayesianAstroModule = nullptr;

BayesianAstroModule::BayesianAstroModule()
{
    TheBayesianAstroModule = this;
}

const char* BayesianAstroModule::Version() const
{
    return "1.0.0";
}

IsoString BayesianAstroModule::Name() const
{
    return "BayesianAstro";
}

String BayesianAstroModule::Description() const
{
    return "Distribution-aware image stacking with per-pixel confidence scoring. "
           "Uses Welford's algorithm for numerically stable statistics accumulation, "
           "automatic distribution classification, and intelligent fusion strategies.";
}

String BayesianAstroModule::Company() const
{
    return "EZ Suite";
}

String BayesianAstroModule::Author() const
{
    return "Scott Carter";
}

String BayesianAstroModule::Copyright() const
{
    return "Copyright (c) 2025 Scott Carter. All rights reserved.";
}

String BayesianAstroModule::TradeMarks() const
{
    return "";
}

String BayesianAstroModule::OriginalFileName() const
{
#ifdef __PCL_WINDOWS
    return "BayesianAstro.dll";
#elif defined(__PCL_MACOSX)
    return "BayesianAstro.dylib";
#else
    return "BayesianAstro.so";
#endif
}

void BayesianAstroModule::GetReleaseDate(int& year, int& month, int& day) const
{
    year = 2025;
    month = 12;
    day = 30;
}

} // namespace pcl

// Module entry points

PCL_MODULE_EXPORT int InstallPixInsightModule(int mode)
{
    new pcl::BayesianAstroModule;

    if (mode == pcl::InstallMode::FullInstall)
    {
        // Initialize Julia runtime
        try
        {
            if (!pcl::JuliaRuntime::Instance().Initialize())
            {
                pcl::Console().CriticalLn("** BayesianAstro: Failed to initialize Julia runtime");
                // Continue anyway - will fail gracefully at execution time
            }
        }
        catch (...)
        {
            pcl::Console().WarningLn("** BayesianAstro: Julia initialization deferred");
        }

        new pcl::BayesianAstroProcess;
        new pcl::BayesianAstroInterface;
    }

    return 0;
}
