

function config(){
    var ini = [
        {
            name: '98 gene panel',
            roi: {x0: 6150, x1: 13751, y0: 12987, y1: 18457},
            imageSize: [16384, 11791],
            cellData: './dashboard/data/img/default_98genes/json/iss.json',
            geneData: './dashboard/data/img/default_98genes/json/Dapi_overlays.json',
            tiles: './dashboard/data/img/default_98genes/16384px/{z}/{x}/{y}.png'
        },

        {
            name: 'User defined',
            roi: roiCookie? JSON.parse(roiCookie):'', // roiCookie has to be a string of this form: {"x0": 6150, "x1": 13751, "y0": 12987, "y1": 18457}. Note the inner double quotes!!!
            imageSize: imageSizeCookie? JSON.parse(imageSizeCookie):'', //[16384, 11791],
            cellData: issFileCookie,   // read that from a cookie
            geneData: spotsFileCookie, // and this one, comes from a cookie too
            tiles: tilesCookie + '/{z}/{x}/{y}.png' // and that one as well!
        },
    ];
    var out = d3.map(ini, function (d) {return d.name;});
    return out
}
