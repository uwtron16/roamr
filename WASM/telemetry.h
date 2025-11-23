#pragma once
#include <mutex>
#include <thread>
#include <chrono>
#include <iomanip>
#include <iostream>

#include "imu.h"

constexpr int log_interval_ms = 100;

void log_sensors(std::mutex& m_imu, const IMUData& imu_data);
