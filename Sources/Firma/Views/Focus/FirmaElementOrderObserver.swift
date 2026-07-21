//
//  Copyright (c) 2026 @mtzaquia
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Observation

@MainActor
final class FirmaElementOrderObserver {
    private var generation = 0
    private var elementOrder: FirmaElementOrder?
    private var onUpdate: ((FirmaElementOrderSnapshot) -> Void)?

    func start(
        observing elementOrder: FirmaElementOrder,
        onUpdate: @escaping (FirmaElementOrderSnapshot) -> Void
    ) {
        generation += 1
        self.elementOrder = elementOrder
        self.onUpdate = onUpdate
        observe(generation: generation)
    }

    func stop() {
        generation += 1
        elementOrder = nil
        onUpdate = nil
    }

    private func observe(generation: Int) {
        guard generation == self.generation else { return }

        guard let elementOrder else { return }
        let snapshot = withObservationTracking {
            FirmaElementOrderSnapshot(
                listPath: elementOrder.listPath,
                ids: elementOrder.currentIDs()
            )
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.observe(generation: generation)
            }
        }
        onUpdate?(snapshot)
    }
}
