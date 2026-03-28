//
//  MainTabBarController.swift
//  QuanLy_PhongTroj
//
//  Created by mac on 18/3/26.
//

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }
    
    func setupTabs() {
        // Tuỳ chỉnh cho các ViewController đã được Storyboard load vào TabBar
        guard let viewControllers = self.viewControllers else { return }
        
        // Tab 0: Home (Navigation Controller)
        if let navHome = viewControllers.first as? UINavigationController {
            navHome.isNavigationBarHidden = true
            navHome.tabBarItem = UITabBarItem(title: "Trang chủ", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))
        }
        
        // Cấu hình các tab còn lại nếu cần
        if viewControllers.count > 1 {
            viewControllers[1].tabBarItem = UITabBarItem(title: "Đã lưu", image: UIImage(systemName: "heart"), selectedImage: UIImage(systemName: "heart.fill"))
        }
        if viewControllers.count > 2 {
            viewControllers[2].tabBarItem = UITabBarItem(title: "Tin nhắn", image: UIImage(systemName: "message"), selectedImage: UIImage(systemName: "message.fill"))
        }
        if viewControllers.count > 3 {
            viewControllers[3].tabBarItem = UITabBarItem(title: "Tài khoản", image: UIImage(systemName: "person"), selectedImage: UIImage(systemName: "person.fill"))
        }
    }
    
    func setupAppearance() {
        tabBar.tintColor = UIColor(hex: "#FF6600")
        tabBar.backgroundColor = .white
        tabBar.unselectedItemTintColor = .lightGray
        
        // Đường viền mờ ở trên tabbar
        tabBar.layer.borderWidth = 0.5
        tabBar.layer.borderColor = UIColor.systemGray5.cgColor
        tabBar.clipsToBounds = true
    }
}
