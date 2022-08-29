//
//  File.swift
//  
//
//  Created by zhtg on 2022/8/21.
//

import Vapor

protocol CommonController: RouteCollection {
    
    associatedtype ModelType: ContentModel
    
    static func schema() -> String

    func query(req: Request) async throws -> ModelType
    
    func list(req: Request) async throws -> [ModelType]

    func create(req: Request) async throws -> HTTPStatus

    func update(req: Request) async throws -> HTTPStatus

    func delete(req: Request) async throws -> HTTPStatus
}

extension CommonController {
    
    static func schema() -> String {
        return ModelType.schema
    }
    
    func boot(routes: RoutesBuilder) throws {
        
        routes.group("\(Self.schema())") { builder in
            // 添加
            builder.post(use: create)

            // 更新
            builder.patch(":id", use: update)

            // 删除
            builder.delete(":id", use: delete)

            // 详情
            builder.get(":id", use: query)

            // 列出所有组件
            builder.get(use: list)
        }
    }
    
    func create(req: Request) async throws -> HTTPStatus {
        // 验证参数的合法性
        try ModelType.validate(content: req)
        if let old = try? await query(req: req) {
            if (old.id != nil) {
                throw AbortBadRequest("\(ModelType.self)已存在")
            }
        }
        // 转成对象
        let module = try req.content.decode(ModelType.self)
        // 保存到数据库
        try await module.save(on: req.db)
        // 返回注册结果
        return .ok
    }
    
    func query(req: Request) async throws -> ModelType {
        // 先从path中拿出值来查找
        if let id = req.parameters.get("id"),
           let filter = try await filterWithId(id, req: req) {
            return filter
        }
        
        let idKeys = ModelType.idKeys
        for key in idKeys {
            // 先从path中拿出值来查找
            if req.method == .GET {
                if let id = try? req.query.get(String.self, at: key),
                   let filter = try await filterWithId(id, req: req) {
                    return filter
                }
            } else {
                if let id = try? req.content.get(String.self, at: key),
                   let filter = try await filterWithId(id, req: req) {
                    return filter
                }
            }
        }
        throw AbortBadRequest("未找到\(ModelType.self)")
    }
    
    func filterWithId(_ id: String, req: Request) async throws -> ModelType? {
        // 先以uuid来查找
        if let uuid = UUID(uuidString: id) {
            if let module = try await ModelType.find(uuid as? ModelType.IDValue, on: req.db) {
                return module
            }
        }
        else {
            // 再以Name来查找
            let all = try await ModelType.query(on: req.db).all()
            if let filter = ModelType.filterResult(all, id: id) {
                return filter
            }
        }
        return nil
    }

    func list(req: Request) async throws -> [ModelType] {
        let all = try await ModelType.query(on: req.db).all()
        let filter = ModelType.filterResult(all, req: req)
        return filter
    }

    func update(req: Request) async throws -> HTTPStatus {
        let module = try await query(req: req)
        
        try await module.update(on: req.db)
        return .ok
    }

    func delete(req: Request) async throws -> HTTPStatus {
        let module = try await query(req: req)
        try await module.delete(on: req.db)
        return .ok
    }

}
