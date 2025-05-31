# Photono

PhotonoはSwiftUIで開発されたiOSアプリで、写真閲覧と音楽再生機能を組み合わせたマルチメディアアプリです。

## 主な機能

### 📸 写真機能
- **フォトライブラリアクセス**: iOS写真ライブラリからの画像読み込み
- **写真一覧表示**: グリッド形式での写真閲覧
- **写真詳細表示**: 高解像度での写真表示とズーム機能
- **写真情報表示**: EXIF情報や撮影日時の確認
- **権限管理**: 写真ライブラリアクセス許可の適切な処理

### 🎵 音楽機能
- **Apple Music統合**: MusicKitを使用したApple Musicライブラリアクセス
- **楽曲一覧表示**: ライブラリ内楽曲のブラウジング
- **音楽再生**: ApplicationMusicPlayerによる楽曲再生
- **楽曲詳細表示**: アルバムアートワークや楽曲情報の表示
- **ミニプレイヤー**: 現在再生中楽曲のコンパクト表示と基本操作

## 技術仕様

- **フレームワーク**: SwiftUI
- **最小対応iOS**: iOS 17+
- **並行処理**: Swift Concurrency (async/await)
- **アーキテクチャ**: Actor-based services
- **依存ライブラリ**: Photos Framework, MusicKit
- **ローカライゼーション**: 日本語対応

## アーキテクチャ

### サービス層
- `PhotoLibrary`: Photos Frameworkのactor-based wrapper
- `MusicPlayer`: ApplicationMusicPlayerのasync wrapper
- `AppleMusicAPIClient`: Apple Music API連携

### ビュー構造
- タブベースナビゲーション（写真・音楽）
- 機能別コンポーネント分割
- 再利用可能なUIコンポーネント

## 開発環境

- Xcode 15.0+
- Swift 5.9+
- iOS Simulator または実機
