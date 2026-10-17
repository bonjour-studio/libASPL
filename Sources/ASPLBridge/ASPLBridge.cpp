//
//  ASPLBridge.cpp
//  ASPLBridge
//
//  Created by Bonjour, LLC on 2026/10/17.
//

#include "ASPLBridge.h"
#include <aspl/Driver.hpp>

#include <memory>
#include <utility>

struct ASPLDriverHandle {
    std::shared_ptr<aspl::Driver> driver;
};

ASPLDriverHandle* ASPLDriverCreate(
    const char* name,
    const char* manufacturer,
    const char* uid,
    UInt32 sampleRate,
    UInt32 channelCount,
    bool inputEnabled,
    bool outputEnabled)
{
    // C++ exceptions must not cross the C boundary into Swift.
    try {
        auto context = std::make_shared<aspl::Context>();
        aspl::DeviceParameters parameters;
        parameters.Name = name;
        parameters.Manufacturer = manufacturer;
        parameters.DeviceUID = uid;
        parameters.SampleRate = sampleRate;
        parameters.ChannelCount = channelCount;

        auto device = std::make_shared<aspl::Device>(context, parameters);
        if (inputEnabled) {
            device->AddStreamWithControlsAsync(aspl::Direction::Input);
        }
        if (outputEnabled) {
            device->AddStreamWithControlsAsync(aspl::Direction::Output);
        }

        aspl::PluginParameters pluginParameters;
        pluginParameters.Manufacturer = manufacturer;
        auto plugin = std::make_shared<aspl::Plugin>(context, pluginParameters);
        plugin->AddDevice(device);
        auto driver = std::make_shared<aspl::Driver>(context, plugin);
        return new ASPLDriverHandle{std::move(driver)};
    } catch (...) {
        return nullptr;
    }
}

void ASPLDriverDestroy(ASPLDriverHandle* handle)
{
    delete handle;
}

AudioServerPlugInDriverRef ASPLDriverGetReference(ASPLDriverHandle* handle)
{
    return handle->driver->GetReference();
}
