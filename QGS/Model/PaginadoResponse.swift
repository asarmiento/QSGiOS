import Foundation

struct PaginadoResponse<T: Codable>: Codable {
    let currentPage: Int
    let data: [T]
    let firstPageURL: String
    let lastPage: Int
    let lastPageURL: String
    let nextPageURL: String?
    let prevPageURL: String?
    let total: Int

    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case data
        case firstPageURL = "first_page_url"
        case lastPage = "last_page"
        case lastPageURL = "last_page_url"
        case nextPageURL = "next_page_url"
        case prevPageURL = "prev_page_url"
        case total
    }
} 