//
//  ViewController.swift
//  ESRI Scratch
//
//  Created by Jake Shapley on 9/30/18.
//  Copyright © 2018 Jake Shapley. All rights reserved.
//

import UIKit
import ArcGIS

class ViewController: UIViewController, AGSCalloutDelegate, AGSGeoViewTouchDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var mapView: AGSMapView!
    
    var waypointGraphic = AGSGraphic()
    var selectedWayPointImageView = UIImageView()
    var wayPointLayer = AGSGraphicsOverlay()
    var selectedPointLayer = AGSGraphicsOverlay()
    var lastQuery: AGSCancelable!
    
    // MARK: Load

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initMap()
    }

    // MARK: Initializers
    
    fileprivate func initMap() {
        let map = AGSMap(basemap: AGSBasemap.lightGrayCanvasVector())
        self.mapView.map = map
        self.mapView.touchDelegate = self
        self.mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -13454510, y: 6071864, spatialReference: AGSSpatialReference.webMercator()), scale: 8000000), completion: nil)
        self.updateWaypointGeometry()
    }
    
    // MARK: Waypoints
    
    fileprivate var waypoints: [(id: String, name: String, loc: CLLocationCoordinate2D)] {
        get {
            var points = [(id: String, name: String, loc: CLLocationCoordinate2D)]()
            points.append((id: "1", name: "Car", loc: CLLocationCoordinate2D(latitude: 46.323, longitude: -123.221)))
            points.append((id: "2", name: "Park", loc: CLLocationCoordinate2D(latitude: 46.446, longitude: -118.619)))
            points.append((id: "3", name: "Tree", loc: CLLocationCoordinate2D(latitude: 46.567, longitude: -122.521)))
            points.append((id: "4", name: "Old House", loc: CLLocationCoordinate2D(latitude: 47.237, longitude: -122.421)))
            points.append((id: "5", name: "Bird", loc: CLLocationCoordinate2D(latitude: 47.667, longitude: -122.123)))
            points.append((id: "6", name: "Truck", loc: CLLocationCoordinate2D(latitude: 46.667, longitude: -121.123)))
            points.append((id: "7", name: "School", loc: CLLocationCoordinate2D(latitude: 48.667, longitude: -119.123)))
            return points
        }
    }
    
    fileprivate func updateWaypointGeometry() {
        self.mapView.graphicsOverlays.remove(self.wayPointLayer)
        self.wayPointLayer.graphics.removeAllObjects()
        if waypoints.count > 0 {
            let wgs84 = AGSSpatialReference.wgs84()
            let symbol = AGSPictureMarkerSymbol(image: UIImage(named: "waypointMarker")!)
            symbol.height = 13
            symbol.width = 15
            symbol.offsetX = 0
            symbol.offsetY = 0
            for point in waypoints {
                let id = point.id
                let name = point.name
                let attributes = ["id": id, "name": name]
                let lat = point.loc.latitude
                let long = point.loc.longitude
                let loc = AGSPoint(x: long, y: lat, spatialReference: wgs84)
                let graphic = AGSGraphic(geometry: loc, symbol: symbol, attributes: attributes)
                self.wayPointLayer.graphics.add(graphic)
            }
            self.mapView.graphicsOverlays.add(self.wayPointLayer)
        }
    }
    
    fileprivate func updateSelectedWaypointGeometry(at point: AGSPoint, attributes: NSMutableDictionary?) -> Void {
        self.waypointGraphic.isVisible = false
        self.mapView.graphicsOverlays.remove(self.selectedPointLayer)
        self.selectedPointLayer.graphics.removeAllObjects()
        self.selectedWayPointImageView = UIImageView(image: UIImage(named: "waypointFilled"))
        let cgCenter = self.mapView.location(toScreen: point)
        let rect = CGRect(x: cgCenter.x - 10.0, y: cgCenter.y - 10.0, width: 20, height: 20)
        self.selectedWayPointImageView.frame = rect
        self.view.addSubview(self.selectedWayPointImageView)
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseInOut], animations:
            {
                self.selectedWayPointImageView.transform = CGAffineTransform(scaleX: 1.3, y: 1.8).translatedBy(x: 0, y: -8)
        }
            , completion: { _ in
                let symbol = AGSPictureMarkerSymbol(image: UIImage(named: "waypointFilled")!)
                symbol.height = 35
                symbol.width = 25
                symbol.offsetX = 0
                symbol.offsetY = 18
                let graphic = AGSGraphic(geometry: point, symbol: symbol, attributes: attributes as! [String : Any])
                self.selectedPointLayer.graphics.add(graphic)
                self.mapView.graphicsOverlays.add(self.selectedPointLayer)
                //sleep(2)
                DispatchQueue.main.asyncAfter(deadline: (DispatchTime.now() + .milliseconds(200)), execute: {
                    self.selectedWayPointImageView.alpha = 0.0
                    self.selectedWayPointImageView.removeFromSuperview()
                })
        })
    }
    
    // MARK: GeoView Touch Delegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if let lastQuery = self.lastQuery {
            lastQuery.cancel()
        }
        if waypoints.count > 0 {
            self.waypointGraphic.isVisible = true
            self.lastQuery = self.mapView.identify(self.wayPointLayer, screenPoint: screenPoint, tolerance: 8.0, returnPopupsOnly: false, maximumResults: 1, completion: { [weak self] (identifyLayerResult: AGSIdentifyGraphicsOverlayResult?) -> Void in
                if let graphics = identifyLayerResult?.graphics, graphics.count > 0 {
                    let generator = UISelectionFeedbackGenerator()
                    generator.selectionChanged()
                    self?.waypointGraphic = graphics[0]
                    let attributes = self?.waypointGraphic.attributes
                    let mapPoint = self?.waypointGraphic.geometry?.extent.center
                    self?.updateSelectedWaypointGeometry(at: mapPoint!, attributes: attributes)
                } else {
                    self?.mapView.graphicsOverlays.remove(self?.selectedPointLayer)
                    self?.selectedPointLayer.graphics.removeAllObjects()
                }
            })
        }
    }
}

