import SathiCore
import Testing

@Suite("CopywriterTodoPageCount")
struct CopywriterTodoPageCountTests {
    @Test(arguments: [
        (23, Int?.some(7), "23 open · 7 lists"),
        (1, Int?.some(1), "1 open · 1 list"),
        (5, Int?.none, "5 open"),
        (0, Int?.none, "0 open")
    ])
    func pageCount(_ open: Int, _ lists: Int?, _ expected: String) {
        #expect(Copywriter.todoPageCount(open: open, lists: lists) == expected)
    }
}
