import Foundation

final class ConcurrentDispatcher {
    private let concurrentQueue: DispatchQueue
    
    init(label: String = "concurrentQueue") {
        self.concurrentQueue = DispatchQueue(
            label: label,
            attributes: .concurrent
        )
    }
    
    func asyncBarrier(_ work: @escaping () -> Void) {// Обертка для асинхронного выполнения с барьером
        concurrentQueue.async(flags: .barrier) {
            work()
        }
    }
    
    func async(_ work: @escaping () -> Void) { // Обычное асинхронное выполнение
        concurrentQueue.async {
            work()
        }
    }
    
    // Асинхронный барьер с возвратом результата
    func asyncBarrierResult<T>(_ work: @escaping () -> T, completion: @escaping (T) -> Void) {
        concurrentQueue.async(flags: .barrier) {
            let result = work()
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}
