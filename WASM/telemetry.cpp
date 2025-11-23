#include "telemetry.h"

// log sensors without significant delays in processing
void log_sensors(std::mutex& m_imu, const IMUData& imu_data){
    std::cout << std::fixed << std::setprecision(5);
    while(true){
        std::this_thread::sleep_for(std::chrono::milliseconds(log_interval_ms)); 
        
        IMUData imu_copy;
        {
            std::lock_guard<std::mutex> lk(m_imu);
            imu_copy = imu_data;
        }
        
        std::cout << "T:" << imu_copy.acc_timestamp << " acc:" << imu_copy.acc_x << "," << imu_copy.acc_y << "," << imu_copy.acc_z << std::endl
                    << "T:" << imu_copy.gyro_timestamp << " gyro:" << imu_copy.gyro_x << "," << imu_copy.gyro_y << "," << imu_copy.gyro_z <<
                    std::endl;
    }
};