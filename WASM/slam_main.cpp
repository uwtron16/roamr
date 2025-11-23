#include <iostream>
#include <mutex>
#include <thread>
#include <chrono>
#define WASM_IMPORT(A, B) __attribute__((__import_module__((A)), __import_name__((B))))
struct IMUData {
    double timestamp;
    float acc_x, acc_y, acc_z;
    float gyro_x, gyro_y, gyro_z;
    float mag_x, mag_y, mag_z;
};

WASM_IMPORT("host", "read_imu") void read_imu(IMUData* data);

constexpr int logIntervalMs = 100;

int main(){
    std::mutex m;
    int shared_data = 0;

    auto logSensor = [&m, &shared_data](){
        while(true){
            std::this_thread::sleep_for(std::chrono::milliseconds(logIntervalMs)); 
            std::lock_guard<std::mutex> lk(m);
            IMUData data;
            read_imu(&data);
            std::cout << "Step:" << shared_data 
                      << " T:" << data.timestamp
                      << " Acc:(" << data.acc_x << "," << data.acc_y << "," << data.acc_z << ")"
                      << " Gyro:(" << data.gyro_x << "," << data.gyro_y << "," << data.gyro_z << ")"
                      << " Mag:(" << data.mag_x << "," << data.mag_y << "," << data.mag_z << ")"
                      << std::endl;
        }
    };

    auto incrementData = [&m, &shared_data](){
        while(true){
            std::lock_guard<std::mutex> lk(m);
            ++shared_data;
        }
    };

    std::thread t1(logSensor);
    std::thread t2(incrementData);

    t1.join();
    t2.join();
}
