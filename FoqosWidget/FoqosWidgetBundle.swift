//
//  FoqosWidgetBundle.swift
//  FoqosWidget
//
//  Created by Ali Waseem on 2025-03-11.
//

import SwiftUI
import WidgetKit

@main
struct FoqosWidgetBundle: WidgetBundle {
  var body: some Widget {
    ProfileControlWidget()
    FoqosWidgetLiveActivity()
  }
}
