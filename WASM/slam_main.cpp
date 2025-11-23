#include <iostream>
#include <mutex>
#include <thread>
#include <chrono>

#define WASM_IMPORT(A, B) __attribute__((__import_module__((A)), __import_name__((B))))
WASM_IMPORT("host", "read_imu") float read_imu();

constexpr int logIntervalMs = 100;

int main(){
    std::mutex m;
    int shared_data = 0;

    auto logSensor = [&m, &shared_data](){
        while(true){
            std::this_thread::sleep_for(std::chrono::milliseconds(logIntervalMs)); 
            std::lock_guard<std::mutex> lk(m);
            std::cout << "Step:" << shared_data << ", IMU "<< read_imu() << std::endl;
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
