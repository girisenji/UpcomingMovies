//
//  SavedMoviesViewModel.swift
//  UpcomingMovies
//
//  Created by Alonso on 3/3/19.
//  Copyright © 2019 Alonso. All rights reserved.
//

import Foundation
import UpcomingMoviesDomain

final class SavedMoviesViewModel: SavedMoviesViewModelProtocol {
    
    private let collectionOption: ProfileCollectionOption
    private let interactor: SavedMoviesInteractorProtocol
    
    var title: String?
    
    var startLoading: Bindable<Bool> = Bindable(false)
    var viewState: Bindable<SimpleViewState<Movie>> = Bindable(.initial)
    
    private var movies: [Movie] {
        return viewState.value.currentEntities
    }
    
    var movieCells: [SavedMovieCellViewModel] {
        return movies.compactMap { SavedMovieCellViewModel($0) }
    }
    
    var needsPrefetch: Bool {
        return viewState.value.needsPrefetch
    }
    
    // MARK: - Initializers
    
    init(collectionOption: ProfileCollectionOption, interactor: SavedMoviesInteractorProtocol) {
        self.collectionOption = collectionOption
        self.interactor = interactor
        
        self.title = collectionOption.title
    }
    
    // MARK: - Public
    
    func movie(at index: Int) -> Movie {
        return movies[index]
    }
    
    // MARK: - Networking
    
    func getCollectionList() {
        let showLoader = viewState.value.isInitialPage
        fetchCollectionList(page: viewState.value.currentPage, option: collectionOption, showLoader: showLoader)
    }
    
    func refreshCollectionList() {
        fetchCollectionList(page: 1, option: collectionOption, showLoader: false)
    }
    
    private func fetchCollectionList(page: Int, option: ProfileCollectionOption, showLoader: Bool) {
        startLoading.value = showLoader
        switch option {
        case .favorites:
            fetchFavoriteList(page: page)
        case .watchlist:
            fetchWatchList(page: page)
        }
    }
    
    private func fetchFavoriteList(page: Int) {
        interactor.getFavoriteList(page: page, completion: { result in
            self.startLoading.value = false
            self.viewState.value = self.processResult(result)
        })
    }
    
    private func fetchWatchList(page: Int) {
        interactor.getWatchList(page: page, completion: { result in
            self.startLoading.value = false
            self.viewState.value = self.processResult(result)
        })
    }
    
    private func processResult(_ result: Result<[Movie], Error>) -> SimpleViewState<Movie> {
        switch result {
        case .success(let movies):
            return self.viewState(for: movies,
                                  currentPage: self.viewState.value.currentPage,
                                  currentMovies: self.movies)
        case .failure(let error):
            return .error(error)
        }
    }
    
    private func viewState(for movies: [Movie], currentPage: Int,
                           currentMovies: [Movie]) -> SimpleViewState<Movie> {
        var allMovies = currentPage == 1 ? [] : currentMovies
        allMovies.append(contentsOf: movies)
        guard !allMovies.isEmpty else { return .empty }
        
        return movies.isEmpty ? .populated(allMovies) : .paging(allMovies, next: currentPage + 1)
    }
    
}
