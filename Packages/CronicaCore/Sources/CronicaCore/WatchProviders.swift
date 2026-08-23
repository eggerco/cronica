//
//  WatchProviders.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 14/01/23.
//

import Foundation

public struct WatchProviders: Codable, Hashable {
    public var results: Results?
}

public struct Results: Codable, Hashable {
    public var ae: ProviderItem?
    public var ag: ProviderItem?
    public var al, ar, at, au: ProviderItem?
    public var ba: ProviderItem?
    public var bb: ProviderItem?
    public var be, bg, bh, bo: ProviderItem?
    public var br: ProviderItem?
    public var bs: ProviderItem?
    public var ca, ch, cl, co: ProviderItem?
    public var cr, cz, de, dk: ProviderItem?
    public var resultsDO: ProviderItem?
    public var dz: ProviderItem?
    public var ec, ee, eg, es: ProviderItem?
    public var fi, fr, gb: ProviderItem?
    public var gf: ProviderItem?
    public var gr, gt, hk, hn: ProviderItem?
    public var hr, hu, id, ie, il: ProviderItem?
    public var resultsIN: ProviderItem?
    public var iq: ProviderItem?
    public var resultsIS, it, jm, jo: ProviderItem?
    public var jp: ProviderItem?
    public var kr: ProviderItem?
    public var kw: ProviderItem?
    public var lb, lt, lv: ProviderItem?
    public var ly, ma: ProviderItem?
    public var md, mk: ProviderItem?
    public var mt: ProviderItem?
    public var mx, my, nl, no: ProviderItem?
    public var nz, om, pa, pe: ProviderItem?
    public var ph, pl: ProviderItem?
    public var ps: ProviderItem?
    public var pt, py: ProviderItem?
    public var qa, ro, rs: ProviderItem?
    public var sa, se, sg, si: ProviderItem?
    public var sk, sv, th: ProviderItem?
    public var tn: ProviderItem?
    public var tr, tt, tw, us: ProviderItem?
    public var uy, ve: ProviderItem?
    public var ye: ProviderItem?
    public var za: ProviderItem?
    enum CodingKeys: String, CodingKey {
        case ae = "AE"
        case ag = "AG"
        case al = "AL"
        case ar = "AR"
        case at = "AT"
        case au = "AU"
        case ba = "BA"
        case bb = "BB"
        case be = "BE"
        case bg = "BG"
        case bh = "BH"
        case bo = "BO"
        case br = "BR"
        case bs = "BS"
        case ca = "CA"
        case ch = "CH"
        case cl = "CL"
        case co = "CO"
        case cr = "CR"
        case cz = "CZ"
        case de = "DE"
        case dk = "DK"
        case resultsDO = "DO"
        case dz = "DZ"
        case ec = "EC"
        case ee = "EE"
        case eg = "EG"
        case es = "ES"
        case fi = "FI"
        case fr = "FR"
        case gb = "GB"
        case gf = "GF"
        case gr = "GR"
        case gt = "GT"
        case hk = "HK"
        case hn = "HN"
        case hr = "HR"
        case hu = "HU"
        case id = "ID"
        case ie = "IE"
        case il = "IL"
        case resultsIN = "IN"
        case iq = "IQ"
        case resultsIS = "IS"
        case it = "IT"
        case jm = "JM"
        case jo = "JO"
        case jp = "JP"
        case kr = "KR"
        case kw = "KW"
        case lb = "LB"
        case lt = "LT"
        case lv = "LV"
        case ly = "LY"
        case ma = "MA"
        case md = "MD"
        case mk = "MK"
        case mt = "MT"
        case mx = "MX"
        case my = "MY"
        case nl = "NL"
        case no = "NO"
        case nz = "NZ"
        case om = "OM"
        case pa = "PA"
        case pe = "PE"
        case ph = "PH"
        case pl = "PL"
        case ps = "PS"
        case pt = "PT"
        case py = "PY"
        case qa = "QA"
        case ro = "RO"
        case rs = "RS"
        case sa = "SA"
        case se = "SE"
        case sg = "SG"
        case si = "SI"
        case sk = "SK"
        case sv = "SV"
        case th = "TH"
        case tn = "TN"
        case tr = "TR"
        case tt = "TT"
        case tw = "TW"
        case us = "US"
        case uy = "UY"
        case ve = "VE"
        case ye = "YE"
        case za = "ZA"
    }
}

public struct ProviderItem: Codable, Hashable {
    public var link: String?
    public var buy, rent, flatrate, free: [WatchProviderContent]?
}

public extension ProviderItem {
    var itemLink: URL? {
        if let link {
            return URL(string: link)
        }
        return nil
    }
}

public struct WatchProviderContent: Codable, Hashable {
    public var logoPath: String?
    public var providerId: Int?
    public var providerName: String?
    public var displayPriority: Int?
}

public extension WatchProviderContent {
    public var providerTitle: String {
        providerName ?? NSLocalizedString("Not Available", comment: "")
    }
    public var itemId: Int {
        providerId ?? 1000
    }
    public var itemPriority: Int {
        providerId ?? 100
    }
    public var providerImage: URL? {
        return NetworkService.urlBuilder(size: .original, path: logoPath)
    }
    public var listPriority: Int {
        return displayPriority ?? 10
    }
    public var itemID: String {
        return "@\(itemId)-\(providerTitle)"
    }
}

public struct WatchProviderResultContent: Codable {
    public var results: [WatchProviderContent]
}
