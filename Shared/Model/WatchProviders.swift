//
//  WatchProviders.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 14/01/23.
//

import Foundation

struct WatchProviders: Codable, Hashable {
    var results: Results?
}

struct Results: Codable, Hashable {
    var ae: ProviderItem?
    var ag: ProviderItem?
    var al, ar, at, au: ProviderItem?
    var ba: ProviderItem?
    var bb: ProviderItem?
    var be, bg, bh, bo: ProviderItem?
    var br: ProviderItem?
    var bs: ProviderItem?
    var ca, ch, cl, co: ProviderItem?
    var cr, cz, de, dk: ProviderItem?
    var resultsDO: ProviderItem?
    var dz: ProviderItem?
    var ec, ee, eg, es: ProviderItem?
    var fi, fr, gb: ProviderItem?
    var gf: ProviderItem?
    var gr, gt, hk, hn: ProviderItem?
    var hr, hu, id, ie, il: ProviderItem?
    var resultsIN: ProviderItem?
    var iq: ProviderItem?
    var resultsIS, it, jm, jo: ProviderItem?
    var jp: ProviderItem?
    var kr: ProviderItem?
    var kw: ProviderItem?
    var lb, lt, lv: ProviderItem?
    var ly, ma: ProviderItem?
    var md, mk: ProviderItem?
    var mt: ProviderItem?
    var mx, my, nl, no: ProviderItem?
    var nz, om, pa, pe: ProviderItem?
    var ph, pl: ProviderItem?
    var ps: ProviderItem?
    var pt, py: ProviderItem?
    var qa, ro, rs: ProviderItem?
    var sa, se, sg, si: ProviderItem?
    var sk, sv, th: ProviderItem?
    var tn: ProviderItem?
    var tr, tt, tw, us: ProviderItem?
    var uy, ve: ProviderItem?
    var ye: ProviderItem?
    var za: ProviderItem?
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

struct ProviderItem: Codable, Hashable {
    var link: String?
    var buy, rent, flatrate, free: [WatchProviderContent]?
}

extension ProviderItem {
    var itemLink: URL? {
        if let link {
            return URL(string: link)
        }
        return nil
    }
}

struct WatchProviderContent: Codable, Hashable {
    var logoPath: String?
    var providerId: Int?
    var providerName: String?
    var displayPriority: Int?
}

extension WatchProviderContent {
    var providerTitle: String {
        providerName ?? NSLocalizedString("Not Available", comment: "")
    }
    var itemId: Int {
        providerId ?? 1000
    }
    var itemPriority: Int {
        providerId ?? 100
    }
    var providerImage: URL? {
        return NetworkService.urlBuilder(size: .medium, path: logoPath)
    }
    var listPriority: Int {
        return displayPriority ?? 10
    }
    var itemID: String {
        return "@\(itemId)-\(providerTitle)"
    }
}

struct WatchProviderResultContent: Codable {
    var results: [WatchProviderContent]
}
