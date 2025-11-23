#include <mutex>
#include <thread>
#include <chrono>

#include "imu.h"
#include "telemetry.h"

int main(){
    std::mutex m_imu;
    IMUData data;

    std::thread imu_thread([&m_imu, &data](){
        while(true){
            std::this_thread::sleep_for(std::chrono::milliseconds(IMUIntervalMs));
            std::lock_guard<std::mutex> lk(m_imu);
            read_imu(&data);
        }
    });
    std::thread telemetry_thread(log_sensors, std::ref(m_imu), std::cref(data));

    imu_thread.join();
    telemetry_thread.join();
}
