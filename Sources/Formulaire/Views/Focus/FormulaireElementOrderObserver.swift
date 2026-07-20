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
final class FormulaireElementOrderObserver {
    private var generation = 0
    private var elementOrders: [FormulaireElementOrder] = []
    private var onUpdate: (([FormulaireElementOrderSnapshot]) -> Void)?

    func start(
        observing elementOrders: [FormulaireElementOrder],
        onUpdate: @escaping ([FormulaireElementOrderSnapshot]) -> Void
    ) {
        generation += 1
        self.elementOrders = elementOrders
        self.onUpdate = onUpdate
        observe(generation: generation)
    }

    func stop() {
        generation += 1
        elementOrders = []
        onUpdate = nil
    }

    private func observe(generation: Int) {
        guard generation == self.generation else { return }

        let snapshots = withObservationTracking {
            elementOrders.map {
                FormulaireElementOrderSnapshot(
                    listPath: $0.listPath,
                    ids: $0.currentIDs()
                )
            }
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.observe(generation: generation)
            }
        }
        onUpdate?(snapshots)
    }
}
