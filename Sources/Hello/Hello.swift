import _Differentiation
struct Hello {
    var text = "Hello, World!"
}
func foo<T: Differentiable>(_ x: T, _ y: T.TangentVector) {}
