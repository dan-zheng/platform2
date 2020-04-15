//******************************************************************************
// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
import XCTest
import Foundation
import SwiftRT

class test_Shape: XCTestCase {
    //==========================================================================
    // support terminal test run
    static var allTests = [
        ("test_reshape", test_reshape),
        ("test_SequentialViews", test_SequentialViews),
        ("test_transposed", test_transposed),
    ]

    //--------------------------------------------------------------------------
    // test_reshape
    func test_reshape() {
        let a3 = array(0..<12, (2, 3, 2))
        let a2 = reshape(a3, (2, -1))
        XCTAssert(a2.shape == [2, 6])
        XCTAssert(a2 == [[0, 1, 2, 3, 4, 5], [6, 7, 8, 9, 10, 11]])
        
        let a1 = reshape(a3, -1)
        XCTAssert(a1 == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        
        let b2 = reshape(a1, (2, -1))
        XCTAssert(b2 == [[0, 1, 2, 3, 4, 5], [6, 7, 8, 9, 10, 11]])

        let b3 = reshape(a1, (2, 2, 3))
//        XCTAssert(b2

    }
    
    //--------------------------------------------------------------------------
    // test_expanding
    func test_expanding() {
        let a = array(0..<4)
        let b = expand(dims: a, axis: 0)
        XCTAssert(b.shape == [1, 4])
        XCTAssert(b.strides == [4, 1])
        XCTAssert(b == [[0, 1, 2, 3]])
        
        let c = expand(dims: b, axes: (3, 0))
        XCTAssert(c.shape == [1, 1, 4, 1])
        XCTAssert(c.strides == [4, 4, 1, 1])
        XCTAssert(c == [[[[0], [1], [2], [3]]]])
    }
    
    //--------------------------------------------------------------------------
    // test_perfTensor1
    func test_perfTensor1() {
        #if !DEBUG
        let a = ones(1024 * 1024)
        var count: DType = 0
        self.measure {
            for value in a {
                count += value
            }
        }
        XCTAssert(count > 0)
        #endif
    }
        
    //--------------------------------------------------------------------------
    // test_perfTensor2
    func test_perfTensor2() {
        #if !DEBUG
        let a = ones((1024, 1024))
        var count: DType = 0
        
        // 0.001s
        self.measure {
            for value in a {
                count += value
            }
        }
        XCTAssert(count > 0)
        #endif
    }

    //--------------------------------------------------------------------------
    // test_perfRepeatedTensor3
    func test_perfRepeatedTensor3() {
        #if !DEBUG
        let a = repeating(1, (64, 128, 128))
        var count: DType = 0
        self.measure {
            for value in a {
                count += value
            }
        }
        XCTAssert(count > 0)
        #endif
    }
    
    //--------------------------------------------------------------------------
    // test_perfTensor3
    func test_perfTensor3() {
        #if !DEBUG
        let a = ones((64, 128, 128))
        var count: DType = 0
        self.measure {
            for value in a {
                count += value
            }
        }
        XCTAssert(count > 0)
        #endif
    }
    
    //--------------------------------------------------------------------------
    // test_perfTensor4
    func test_perfTensor4() {
        #if !DEBUG
        let a = ones((2, 32, 128, 128))
        var count: DType = 0
        self.measure {
            for value in a {
                count += value
            }
        }
        XCTAssert(count > 0)
        #endif
    }
    
    //--------------------------------------------------------------------------
    // test_perfTensor5
    func test_perfTensor5() {
        #if !DEBUG
        let a = ones((2, 2, 16, 128, 128))
        var count: DType = 0
        self.measure {
            for value in a {
                count += value
            }
        }
        XCTAssert(count > 0)
        #endif
    }
    
    //--------------------------------------------------------------------------
    // test_initRepeating
    func test_initRepeating() {
        #if !DEBUG
        var count: DType = 0
        self.measure {
            for _ in 0..<100000 {
                let a = Tensor1<Float>(repeating: 1, to: Shape1(1))
                count += a.element
            }
        }
        XCTAssert(count > 0)
        #endif
    }
    
    //--------------------------------------------------------------------------
    // test_initSingle
    func test_initSingle() {
        #if !DEBUG
        var count: DType = 0
        self.measure {
            for _ in 0..<100000 {
                let a = Tensor1<Float>(1)
                count += a.element
            }
        }
        XCTAssert(count > 0)
        #endif
    }
    
    //--------------------------------------------------------------------------
    // test_SequentialViews
    func test_SequentialViews() {
        // vector views are always sequential
        let v = array(0..<6)
        let subv = v[1...2]
        XCTAssert(subv.isSequential)
        
        // a batch of rows are sequential
        let m = empty((4, 5))
        let mrows = m[1...2, ...]
        XCTAssert(mrows.isSequential)
        
        // a batch of columns are not sequential
        let m1 = empty((4, 5))
        let mcols = m1[..., 1...2]
        XCTAssert(!mcols.isSequential)
    }
    
    //--------------------------------------------------------------------------
    // test_transposed
    func test_transposed() {
        let m = array(0..<9, (3, 3))
        XCTAssert(m.t == [[0,3,6], [1,4,7], [2,5,8]])
        
        let a = array(0..<24, (2,3,4))
        let transA = a.transposed(permutatedBy: (2,1,0))
        XCTAssert(transA == [[[ 0.0, 12.0],
                              [ 4.0, 16.0],
                              [ 8.0, 20.0]],
                             
                             [[ 1.0, 13.0],
                              [ 5.0, 17.0],
                              [ 9.0, 21.0]],
                             
                             [[ 2.0, 14.0],
                              [ 6.0, 18.0],
                              [10.0, 22.0]],
                             
                             [[ 3.0, 15.0],
                              [ 7.0, 19.0],
                              [11.0, 23.0]]])
    }
}
