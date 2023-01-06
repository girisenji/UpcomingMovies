//
//  RecommendedMoviesCoordinator.swift
//  UpcomingMovies
//
//  Created by Alonso on 29/05/21.
//  Copyright © 2021 Alonso. All rights reserved.
//

import UIKit
import UpcomingMoviesDomain

final class RecommendedMoviesCoordinator: BaseCoordinator, MovieListCoordinatorProtocol, MovieDetailCoordinable {

    override func start() {
        let viewController = MovieListViewController.instantiate()

        viewController.viewModel = DIContainer.shared.resolve(name: "RecommendedMovies",
                                                              argument: "Recommendations")
        viewController.coordinator = self

        navigationController.pushViewController(viewController, animated: true)
    }

}
