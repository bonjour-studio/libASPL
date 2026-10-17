//
//  main.cpp
//  CxxConsumer
//
//  Created by Bonjour, LLC on 2026/10/17.
//

#include <aspl/Driver.hpp>

#include <iostream>
#include <memory>

int main()
{
    auto tracer = std::make_shared<aspl::Tracer>(aspl::Tracer::Mode::Noop);
    auto context = std::make_shared<aspl::Context>(tracer);
    aspl::DeviceParameters parameters;
    parameters.Name = "Standalone C++ Consumer";
    parameters.DeviceUID = "com.example.aspl.cpp-consumer";
    parameters.SampleRate = 48000;
    parameters.ChannelCount = 1;
    auto device = std::make_shared<aspl::Device>(context, parameters);
    auto stream = device->AddStreamWithControlsAsync(aspl::Direction::Input);
    auto plugin = std::make_shared<aspl::Plugin>(context);
    plugin->AddDevice(device);
    auto driver = std::make_shared<aspl::Driver>(context, plugin);
    auto reference = driver->GetReference();
    if (!reference || !*reference || plugin->GetDeviceCount() != 1 ||
        plugin->GetDeviceByIndex(0) != device ||
        device->GetStreamCount(aspl::Direction::Input) != 1 ||
        stream->GetChannelCount() != 1 || stream->GetSampleRate() != 48000) {
        std::cerr << "C++ object graph validation failed\n";
        return 1;
    }

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyNominalSampleRate,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMain
    };
    Float64 sampleRate = 0;
    UInt32 size = 0;
    OSStatus result = (*reference)->GetPropertyData(
        reference, device->GetID(), 0, &address,
        0, nullptr, sizeof(sampleRate), &size, &sampleRate);
    if (result != noErr || size != sizeof(sampleRate) || sampleRate != 48000) {
        std::cerr << "C++ HAL interface validation failed\n";
        return 2;
    }
    std::cout << "C++ consumer passed: public headers, product linkage, and HAL interface\n";
}
