//
//  MovieDetailViewModel.swift
//  UpcomingMovies
//
//  Created by Alonso on 11/7/18.
//  Copyright © 2018 Alonso. All rights reserved.
//

import Foundation
import UpcomingMoviesDomain

final class MovieDetailViewModel: MovieDetailViewModelProtocol {

    // MARK: - Dependencies
    
    private let interactor: MovieDetailInteractorProtocol
    private let factory: MovieDetailFactoryProtocol

    // MARK: - Reactive properties

    private (set) var startLoading: Bindable<Bool> = Bindable(false)
    private (set) var isFavorite: Bindable<Bool> = Bindable(false)
    private (set) var favoriteState: Bindable<MovieDetailFavoriteState> = Bindable(.unknown)
    private (set) var showErrorView: Bindable<Error?> = Bindable(nil)
    private (set) var showGenreName: Bindable<String> = Bindable("-")
    private (set) var showMovieOptions: Bindable<[MovieDetailOption]> = Bindable([])

    private (set) var didUpdateMovieDetail: Bindable<Bool> = Bindable(true)

    private (set) var didUpdateFavoriteSuccess: Bindable<Bool> = Bindable(false)
    private (set) var didUpdateFavoriteFailure: Bindable<Error?> = Bindable(nil)

    var shouldHideFavoriteButton: (() -> Void)?

    // MARK: - Properties
    
    private (set) var id: Int!
    private (set) var title: String!
    private (set) var releaseDate: String?
    private (set) var overview: String?
    private (set) var voteAverage: Double?
    private (set) var posterURL: URL?
    private (set) var backdropURL: URL?

    private (set) var needsFetch = false
    
    // MARK: - Initializers

    init(_ movie: Movie,
         interactor: MovieDetailInteractorProtocol,
         factory: MovieDetailFactoryProtocol) {
        self.interactor = interactor
        self.factory = factory
        
        setupMovie(movie)

        showGenreName.value = movie.genreName
        showMovieOptions.value = factory.options
    }
    
    init(id: Int, title: String,
         interactor: MovieDetailInteractorProtocol,
         factory: MovieDetailFactoryProtocol) {
        self.id = id
        self.title = title
        self.interactor = interactor
        self.factory = factory
        
        needsFetch = true

        showMovieOptions.value = factory.options
    }

    // MARK: - Private
    
    private func setupMovie(_ movie: Movie) {
        id = movie.id
        title = movie.title
        
        releaseDate = movie.releaseDate
        voteAverage = movie.voteAverage
        overview = movie.overview
        posterURL = movie.posterURL
        backdropURL = movie.backdropURL
        
        getMovieGenreName(for: movie.genreIds?.first)
        saveVisitedMovie()
    }
    
    private func getMovieGenreName(for genreId: Int?) {
        guard let genreId = genreId else { return }
        interactor.findGenre(with: genreId, completion: { [weak self] result in
            guard let strongSelf = self else { return }
            let genre = try? result.get()
            strongSelf.showGenreName.value = genre?.name ?? "-"
        })
    }
    
    // MARK: - Networking
    
    func getMovieDetail() {
        fetchMovieDetail(showLoader: true)
    }
    
    func refreshMovieDetail() {
        fetchMovieDetail(showLoader: false)
    }
    
    private func fetchMovieDetail(showLoader: Bool = true) {
        guard needsFetch else { return }
        startLoading.value = showLoader
        interactor.getMovieDetail(for: id, completion: { result in
            switch result {
            case .success(let movie):
                self.setupMovie(movie)
                self.checkIfMovieIsFavorite(showLoader: false)
                self.didUpdateMovieDetail.value = true
            case .failure(let error):
                self.startLoading.value = false
                self.showErrorView.value = error
            }
        })
    }
    
    func saveVisitedMovie() {
        interactor.saveMovieVisit(with: id, title: title, posterPath: posterURL?.absoluteString)
    }
    
    // MARK: - User Authentication
    
    func checkIfMovieIsFavorite(showLoader: Bool) {
        startLoading.value = showLoader
        checkIfMovieIsFavorite { result in
            self.startLoading.value = false
            switch result {
            case .success(let isFavorite):
                guard let isFavorite = isFavorite else {
                    self.shouldHideFavoriteButton?()
                    return
                }
                self.isFavorite.value = isFavorite
            case .failure(let error):
                guard self.needsFetch else { return }
                self.showErrorView.value = error
            }
        }
    }
    
    // MARK: - Favorites
    
    private func checkIfMovieIsFavorite(completion: @escaping (Result<Bool?, Error>) -> Void) {
        guard interactor.isUserSignedIn() else {
            completion(.success(nil))
            return
        }
        interactor.isMovieInFavorites(for: id, completion: { result in
            switch result {
            case .success(let isFavorite):
                completion(.success(isFavorite))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
    
    func handleFavoriteMovie() {
        let newFavoriteValue = !isFavorite.value
        interactor.markMovieAsFavorite(movieId: id, favorite: newFavoriteValue, completion: { result in
            switch result {
            case .success:
                self.isFavorite.value = newFavoriteValue
                self.didUpdateFavoriteSuccess.value = newFavoriteValue
            case .failure(let error):
                self.didUpdateFavoriteFailure.value = error
            }
        })
    }
    
}
