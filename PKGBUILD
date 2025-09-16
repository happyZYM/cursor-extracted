# Maintainer: Zhuang Yumin <zymx@pm.me>

pkgname=cursor-extracted
pkgver=1.6.26
pkgrel=1
pkgdesc="Cursor App - AI-first coding environment"
arch=('x86_64')
url="https://www.cursor.com/"
license=('custom:Proprietary')  # Replace with the correct license if known
depends=('gtk3' 'nss' 'alsa-lib')
options=(!strip)
_appimage="${pkgname}-${pkgver}.AppImage"
source_x86_64=("${_appimage}::https://downloads.cursor.com/production/6af2d906e8ca91654dd7c4224a73ef17900ad735/linux/x64/Cursor-1.6.26-x86_64.AppImage" "cursor.png" "${pkgname}.desktop.in" "${pkgname}.sh")
noextract=("${_appimage}")
sha512sums_x86_64=('100b82d2d33569286c47619d789aee4bfc7d6e3392386be6f3adeea718ebbfa47a1e4dd6566bf14de1376ddee3ad20a3f1de536ec327bf00d5e03b5901bba58b'
                   'f948c5718c2df7fe2cae0cbcd95fd3010ecabe77c699209d4af5438215daecd74b08e03d18d07a26112bcc5a80958105fda724768394c838d08465fce5f473e7'
                   '813d42d46f2e6aad72a599c93aeb0b11a668ad37b3ba94ab88deec927b79c34edf8d927e7bb2140f9147b086562736c3f708242183130824dd74b7a84ece67aa'
                   '07557ecbce45aade220eeb1a7da0b7bc2fee56fe4cb06f9b151224c0a196b6c1bf2e6027e12f4dd76bf9c886ad9388a4a71fe5d6c43c3f36918067aa2748e889')

prepare() {
    # Set correct version in .desktop file
    sed "s/@@PKGVERSION@@/${pkgver}/g" "${srcdir}/${pkgname}.desktop.in" > "${srcdir}/cursor-cursor.desktop"
    
    # Extract AppImage
    cd "${srcdir}"
    chmod +x "${_appimage}"
    ./"${_appimage}" --appimage-extract
}

package() {
    # Create directories
    install -d "${pkgdir}/opt/${pkgname}"
    install -d "${pkgdir}/usr/bin"
    install -d "${pkgdir}/usr/share/applications"
    install -d "${pkgdir}/usr/share/icons"

    # Install extracted AppImage contents
    cp -r "${srcdir}/squashfs-root/"* "${pkgdir}/opt/${pkgname}/"
    
    # Install desktop file and icon
    install -m644 "${srcdir}/cursor-cursor.desktop" "${pkgdir}/usr/share/applications/cursor-cursor.desktop"
    install -m644 "${srcdir}/cursor.png" "${pkgdir}/usr/share/icons/cursor.png"

    # Install executable wrapper script
    install -m755 "${srcdir}/${pkgname}.sh" "${pkgdir}/usr/bin/cursor"
}

post_install() {
    update-desktop-database -q
    xdg-icon-resource forceupdate
}
