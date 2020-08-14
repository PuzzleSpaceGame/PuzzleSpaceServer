export default function(canvas,channel){
    "use strict"; 
    this.count = 0
    channel.on("draw_update", x=> this.dispatch(x.body))
    this.dispatch = element =>{
        if(element.won){
            document.getElementById("game_status").innerHTML = "Puzzle Complete!"
        }
        if(element.lost){
            document.getElementById("game_status").innerHTML = "You lost. Better luck next time."
        }
        if(element.draw === true){
            this.initialize(element.size)
            this.iterate(element.cmds)
            return
        }
        if(element.draw_update){
            this.draw_update(element)
            return
        }
        if(element.clip){
            this.clip(element)
            return
        }
        if(element.draw){
            this.count++
            this.ctx.save()
            this.ctx.beginPath()
            this[element.draw](element)
            this.ctx.restore()
        }

    }
    this.iterate = element_list => {
        element_list.forEach(this.dispatch)
    }
    const rgbToHex = (r, g, b) => '#' + [r, g, b].map(x => {
          const hex = x.toString(16)
          return hex.length === 1 ? '0' + hex : hex
    }).join('')
    this.initialize = size => {
        this.canvas = canvas
        this.canvas.oncontextmenu = function(event) { return false; }
        this.canvas.width = size.x
        this.canvas.height = size.y
        this.ctx = canvas.getContext("2d");
        this.colours = JSON.parse(document.getElementById("colours").textContent).colours
            .map(x => rgbToHex(Math.round(255*x.r),Math.round(255*x.g),Math.round(255*x.b)));
        console.log(this.colours);
        /*
        let palette = document.createElement("canvas")
        palette.width = this.colours.length * 10
        palette.height = 10
        let pctx = palette.getContext("2d");
        this.colours.forEach( (x,i) => {
            pctx.fillStyle = x
            pctx.fillRect(10*i,0,10,10)
        })
        canvas.insertAdjacentElement('afterend',palette);
        */
        this.ctx.imageSmoothingEnabled = false;
    }
    this.get_colour = colint => {
        if(colint < this.colours.length){
            return this.colours[colint]
        }
        console.log(`No match for color: ${colint}`);
        return "red";
    }
    this.get_font = fontint => {
        return "serif"
    }
    this.clip = (element) => {
        let temp = this.count
        this.ctx.save()
        this.ctx.beginPath()
        this.ctx.rect(element.x,element.y,element.w,element.h)
        this.ctx.clip();
        this.iterate(element.cmds)
        this.ctx.restore()
    }
    this.draw_update = element => {
        return
    }
    this.rect = (element) => { 
        this.ctx.fillStyle = this.get_colour(element.colour)
        this.ctx.strokeStyle = this.get_colour(element.colour)
        this.ctx.rect(element.x,element.y,element.w,element.h)
        this.ctx.stroke()
        this.ctx.fill()
    }
    this.circle = (element) => {
        
        this.ctx.arc(element.cx,element.cy,element.radius,0,2*Math.PI)
        if(element.fillcolour != -1){
            this.ctx.fillStyle = this.get_colour(element.fillcolour)
            this.ctx.fill()
        }
        this.ctx.strokeStyle = this.get_colour(element.outlinecolour)
        this.ctx.stroke()
    }
    this.text = (element) => {
        this.ctx.font = `${element.fontsize}px ${this.get_font(element.fonttype)}` 
        let alignmask = ("000" + element.align.toString(16)).slice(-3);
        if(alignmask[2] == "0"){
            // horizontal align LEFT
            this.ctx.textAlign = "left"
        } else if(alignmask[2] == "1"){
            // horizontal align CENTRE
            this.ctx.textAlign = "center"
        } else if(alignmask[2] == "2"){
            // horizontal align RIGHT
            this.ctx.textAlign = "right"
        }
        if(alignmask[0] == "0"){
            // vertial align "NORMAL" (aka with bottom) 
            this.ctx.textBaseline = "alphabetic" // possibly bottom
        } else if(alignmask[0] == "1"){
            // vertial align "CENTRE"
            this.ctx.textBaseline = "middle"
        }
        this.ctx.fillStyle = this.get_colour(element.colour)
        this.ctx.fillText(element.text,element.x,element.y)
        this.ctx.strokeStyle = this.get_colour(element.colour)
        this.ctx.strokeText(element.text,element.x,element.y)
        this.ctx.stroke()
        this.ctx.fill()

    }
    this.polygon = (element) => {
        this.ctx.moveTo(element.coords[0],element.coords[1])
        for(let i=2; i< element.coords.length; i+=2){
            this.ctx.lineTo(element.coords[i],element.coords[i+1])
        }
        this.ctx.closePath()
        if(element.fillcolour != -1){
            this.ctx.fillStyle = this.get_colour(element.fillcolour)
            this.ctx.fill()
        }
        this.ctx.strokeStyle = this.get_colour(element.outlinecolour)
        this.ctx.stroke()
    }
    this.line = (element) => {
        this.ctx.moveTo(element.x1,element.y1)
        this.ctx.lineTo(element.x2,element.y2)
        this.ctx.strokeStyle = this.get_colour(element.colour)
        this.ctx.stroke()
    }
    return this
}
